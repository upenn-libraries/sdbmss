# Debugging JS Test Infrastructure: Solr, DatabaseCleaner, and WEBrick

This document chronicles the investigation and fixes for a cascade of failures in the Rails test suite's JS test infrastructure. All changes landed in `spec/rails_helper.rb`, `config/sunspot.yml`, and `spec/features/smoke_spec.rb`.

---

## Background

JS tests (tagged `:js => true`) use Capybara + Ferrum (headless Chrome) driving a WEBrick app server. Between each test, DatabaseCleaner truncates all MySQL tables and the test database is re-seeded. This is necessary because Capybara's browser runs in a separate thread from the test thread — transactions can't be used for isolation because WEBrick's thread wouldn't see the test thread's uncommitted rows.

The test suite also uses Sunspot/Solr for full-text search. Several models (`Entry`, `Place`, `Comment`, `Name`, etc.) have `searchable do` blocks that add AR callbacks to index documents in Solr on save.

---

## Failure 1: `ActiveRecord::RecordInvalid` crashing `before(:suite)`

### Symptom

The suite crashed immediately on startup before any tests ran:

```
ActiveRecord::RecordInvalid: Validation failed: Username has already been taken, Email has already been taken
  .../seed_data.rb:53:in `create'
  .../spec/rails_helper.rb:89:in `block (2 levels) in <top (required)>'
```

### Investigation

`before(:suite)` runs `SDBMSS::SeedData.create` which calls `User.create!` to create the admin and contributor seed users. But the users already existed — so the uniqueness validation failed.

The code immediately before that call was:

```ruby
DatabaseCleaner.clean_with(:truncation)
```

TRUNCATE is supposed to wipe the users table. Why did it fail?

MySQL enforces foreign key constraints on `TRUNCATE`. The `users` table is referenced by foreign keys in many other tables (bookmarks, comments, group_users, etc.). With `FOREIGN_KEY_CHECKS=1`, MySQL refuses to truncate `users` because it would orphan rows in those child tables. DatabaseCleaner got a silent error and left the table intact.

### Fix

Disable FK checks before truncation, re-enable after seeding:

```ruby
config.before(:suite) do
  ActiveRecord::Base.connection.execute('SET FOREIGN_KEY_CHECKS=0')
  DatabaseCleaner.clean_with(:truncation)
  # ... seed ...
  ActiveRecord::Base.connection.execute('SET FOREIGN_KEY_CHECKS=1')
```

---

## Failure 2: `Ferrum::TimeoutError` on `click_button 'Log in'`

### Symptom

After fixing the startup crash, all 8 tests that called `login()` failed:

```
Ferrum::TimeoutError
  waiting for click_button 'Log in'
```

The login form was submitted, but the browser timed out waiting for a redirect.

### Investigation

The key clue was that this happened on the _second_ JS test (after the first one had run and its `after(:each)` hook had executed). The first test passed; all subsequent ones failed.

RSpec runs `after(:each)` hooks in LIFO (Last In, First Out) order relative to registration. Our custom `after(:each)` hook (registered in rails_helper) ran _before_ Capybara's built-in session cleanup hook (registered by `require 'capybara/rails'`).

Our hook re-seeded the database, which involved calls to `SDBMSS::SeedData.create` and `SDBMSS::ReferenceData.create_all`. These AR operations triggered Sunspot callbacks that made HTTP requests to Solr. With a large number of records, this took 60+ seconds.

While all this was happening, the browser was idle. Ferrum's TCP connection to the WEBrick server timed out. By the time Capybara's cleanup hook ran, the browser was dead. The next test started with a broken browser, so `click_button 'Log in'` never completed.

### Fix

Reset the browser session at the _start_ of our `after(:each)` hook, before the slow re-seeding. Because our hook runs before Capybara's (LIFO), calling `Capybara.reset_sessions!` here restores the browser to a clean state — then Capybara's own cleanup hook has nothing left to do and returns immediately.

```ruby
config.after(:each) do |example|
  if example.metadata[:js]
    Capybara.reset_sessions!   # ← reset BEFORE slow re-seeding
  end
  DatabaseCleaner.clean
  if example.metadata[:js]
    # ... re-seed ...
  end
end
```

---

## Failure 3: `Net::ReadTimeout` during re-seeding

### Symptom

After fixing the Ferrum timeout, tests still failed intermittently during the re-seeding phase in `after(:each)`:

```
Net::ReadTimeout: Net::ReadTimeout with #<TCPSocket:(closed)>
  # (eval):2:in 'post'
```

This appeared in logs during `SDBMSS::ReferenceData.create_all`.

### Investigation

`ReferenceData.create_all` updates `Source` records. The `Source` model includes `IndexAfterUpdate`, which adds an `after_update` callback:

```ruby
def index_after_update
  if Rails.configuration.sdbmss_index_after_update_enabled
    SDBMSS::IndexJob.perform_later(self.class.to_s, [id])
  end
end
```

In test mode, `config.active_job.queue_adapter = :inline`, so `perform_later` runs the job synchronously in the current thread. `IndexJob` calls `Sunspot.index(source_records)` — an RSolr POST to Solr.

The problem: RSolr caches its `Net::HTTP` object per `RSolr::Connection` instance (`@http ||= Net::HTTP.new(...)`). After the previous test's WEBrick activity, the Solr connection's socket was stale (closed by Solr's keepalive timeout). The next POST attempt hit a closed TCP socket and blocked until `Net::ReadTimeout`.

### Fix

Wrap the re-seeding block with `Sunspot::Rails::StubSessionProxy`, a no-op proxy that silences all Sunspot operations (index, remove, commit, search). AR callbacks fire normally and their internal `Sunspot.index(...)` calls go into the stub instead of making real HTTP requests. The Solr state stays valid because `before(:suite)` indexed the seed data, and TRUNCATE resets MySQL's `AUTO_INCREMENT` counters, so the re-seeded records get the same IDs they had before — the Solr index is still consistent.

```ruby
sunspot_session = Sunspot.session
Sunspot.session = Sunspot::Rails::StubSessionProxy.new(sunspot_session)
begin
  SDBMSS::SeedData.create
  SDBMSS::ReferenceData.create_all
  SDBMSS::Mysql.create_functions
ensure
  Sunspot.session = sunspot_session
end
```

---

## Failure 4: `Net::ReadTimeout` on `click_button 'Log in'` (the hard one)

### Symptom

Even after fixing re-seeding, all login tests kept failing:

```
Net::ReadTimeout: Net::ReadTimeout with #<TCPSocket:(closed)>
  # (eval):2:in 'post'
  (from WEBrick request handling thread)
```

The stack trace pointed to RSolr's `post` method being called _during the login HTTP request_, not during re-seeding.

### Investigation

This required tracing what happens inside WEBrick when Devise processes a sign-in POST:

1. Devise authenticates the user
2. Devise's `Trackable` module calls `user.save!` to update `last_sign_in_at`, `sign_in_count`, etc.
3. `User` has a `searchable do` block — Sunspot adds `after_save :perform_index_tasks` to all searchable AR models
4. `perform_index_tasks` calls `Sunspot.index(self)` → RSolr POST to Solr

This happens in **WEBrick's thread**, not the test thread.

#### Why RSolr's socket was closed

`before(:each)` rebuilt the Sunspot session with `Sunspot.session = Sunspot::Rails.build_session`. This creates a new `ThreadLocalSessionProxy` — sessions are stored in `Thread.current[:"sunspot_session_#{object_id}"]`. A new proxy (new `object_id`) means all threads lazily create a fresh `Session.new(config)` on first use, with a new `RSolr::Connection` with `@http = nil`.

When WEBrick first tried to use Sunspot in a test, it initialized a fresh connection. That should have worked. But:

- The connection was to Solr at `solr:8983`
- With many test runs accumulating uncommitted changes, Solr's transaction log grew large
- Eventually Solr commits took > 60 seconds (and eventually > the configured timeout)
- The socket was opened but Solr didn't respond in time → `Net::ReadTimeout with #<TCPSocket:(closed)>`

Additionally, `auto_commit_after_request` was still `true` (the default), so Sunspot's `after_filter :commit_if_dirty` ran after every login request, hitting Solr _again_.

#### Attempts that didn't fully work

1. **Fresh session rebuild** — `Sunspot.session = Sunspot::Rails.build_session` in `before(:each)` — fresh connections, but WEBrick still hits Solr during `perform_index_tasks`. Still timed out.

2. **`auto_commit_after_request: false`** — stopped the `commit_if_dirty` after-filter but `perform_index_tasks` (the actual index POST) still fired. The POST, not the commit, was timing out.

3. **`read_timeout: 2`** — made failures fail fast (2s instead of 60s), converting `Ferrum::TimeoutError` (browser timeout waiting for WEBrick to finish the stuck login) into fast `Net::ReadTimeout` failures. This made it clear the issue was specifically RSolr's `post` call.

#### Root cause: Solr getting stuck

Investigation revealed that Solr itself was getting stuck on commits after multiple test runs. Each run called `Sunspot.commit` in `before(:suite)`. Over time, Solr accumulated a large transaction log from repeated remove-all + index cycles. Eventually even a simple HTTP commit to Solr would hang indefinitely. Verified: `curl -X POST http://solr:8983/solr/test/update -d '{"commit":{}}'` hung for > 60 seconds on a "stuck" Solr.

### Fix

Two-part solution:

**Part 1: Target just the User indexing callback**

Instead of globally stubbing all Sunspot operations (which would break Solr searches in tests), stub only `User#perform_index_tasks`. RSpec's `allow_any_instance_of` patches the class globally — all threads, including WEBrick's, see the stub for the duration of the test:

```ruby
config.before(:each) do |example|
  Sunspot.session = Sunspot::Rails.build_session if example.metadata[:js]
  allow_any_instance_of(User).to receive(:perform_index_tasks)
  DatabaseCleaner.strategy = example.metadata[:js] ? :truncation : :transaction
  DatabaseCleaner.start
end
```

This suppresses only the Solr call that happens during login, while leaving every other model's AR Sunspot callbacks intact. Searches still work because the Solr session is real.

**Part 2: Optimize Solr at suite start to prevent accumulation**

In `before(:suite)`, after indexing and committing, fire an async Solr optimize (merge segments, prune deleted documents) with `waitFlush=false` so it doesn't block startup:

```ruby
Net::HTTP.new(solr_url.host, solr_url.port).post(
  "#{solr_url.path}/update?optimize=true&waitFlush=false&waitSearcher=false",
  '<optimize/>',
  'Content-Type' => 'application/xml'
)
```

This prevents the Solr transaction log from growing unbounded across many test runs, keeping commit times fast.

---

## Failure 5: `ActionView::Template::Error` on search results page

### Symptom

The smoke spec's "searches entries via Solr" test failed with:

```
ActionView::Template::Error: undefined method `id' for nil:NilClass
  app/views/catalog/_bookmark_all.html.erb:3
```

### Investigation

The search results page renders a `_bookmark_all` partial that calls `.id` on each result. When Solr returned entries whose IDs existed in the index but not in the database (stale index entries from a previous test run that created extra records), the partial received a `nil` AR object and crashed.

This was triggered by running tests in a specific random order where a previous test had indexed extra records before truncation, leaving stale Solr entries pointing to non-existent DB rows.

### Fix

Re-sync the Solr Entry index at the **start** of every JS test's `before(:each)`.  With `auto_commit_after_request: true` (necessary for tests that create records via the browser and immediately search for them), any browser request that creates or modifies an Entry auto-commits it to Solr.  After `DatabaseCleaner` truncates the table, those Solr documents remain — IDs that no longer exist in the DB.

Clearing and re-indexing Entry at the top of each JS test ensures every test starts from a consistent Solr state:

```ruby
config.before(:each) do |example|
  if example.metadata[:js]
    Sunspot.session = Sunspot::Rails.build_session  # fresh RSolr connections
    begin
      Sunspot.remove_all(Entry)   # clear stale docs from previous test
      Sunspot.index(Entry.all)    # re-index seed entries (13 records, fast)
      Sunspot.commit
    rescue => e
      Rails.logger.warn "Solr Entry resync before JS test failed: #{e.message}"
    end
  end
  # ...
end
```

`remove_all` (without `!`) stages the delete without committing; the single `Sunspot.commit` at the end commits both the removes and the indexes in one round-trip.  Using the freshly built session means the RSolr HTTP connection is brand new — no stale-socket risk.

---

## Smoke Spec

A lightweight smoke spec (`spec/features/smoke_spec.rb`) was created to exercise all the fixed infrastructure in ~90 seconds:

| Test | What it validates |
|------|-------------------|
| logs in successfully | Login works end-to-end |
| searches entries via Solr | Real Solr query returns results |
| shows places created in before:each | `Place.index` + `Sunspot.commit` pattern works |
| shows group created in before:each | Non-Solr DB records survive truncation+reseed |
| shows comment created in before:each | Comment AR Sunspot callback + commit pattern |
| shows bookmark with tag | Bookmark records survive truncation+reseed |
| notification settings survive truncation | `notification_settings` restored after truncation |
| advanced search finds entries after truncation | Solr index stays valid after reseed (same IDs) |
| redirects to login without session | No login required — basic routing sanity check |
| loads entry history page | PaperTrail works for seed data entries |

Tests that create records and immediately search for them via Solr need an explicit `Sunspot.commit` after creation when the records are created directly in Ruby (not via the browser).  Browser-driven record creation benefits from `auto_commit_after_request: true` (the default), which commits Solr after each WEBrick request automatically.

---

## Final State of `rails_helper.rb` hooks

```ruby
config.before(:suite) do
  ActiveRecord::Base.connection.execute('SET FOREIGN_KEY_CHECKS=0')
  DatabaseCleaner.clean_with(:truncation)
  begin; Sunspot.remove_all!; rescue => e; Rails.logger.warn ...; end
  SDBMSS::SeedData.create
  SDBMSS::ReferenceData.create_all
  SDBMSS::Mysql.create_functions
  ActiveRecord::Base.connection.execute('SET FOREIGN_KEY_CHECKS=1')
  begin
    Sunspot.index(Entry.all)
    Sunspot.commit
  rescue => e; Rails.logger.warn ...; end
  begin
    # Async optimize prevents Solr transaction log buildup across test runs
    Net::HTTP.new(...).post('.../update?optimize=true&waitFlush=false&waitSearcher=false', ...)
  rescue => e; Rails.logger.warn ...; end
end

config.before(:each) do |example|
  # Fresh session so all threads get new RSolr connections (no stale sockets)
  Sunspot.session = Sunspot::Rails.build_session if example.metadata[:js]
  # Stub User#perform_index_tasks globally — patches the class, so WEBrick's
  # thread also sees the stub. Prevents Devise login from POSTing to Solr.
  allow_any_instance_of(User).to receive(:perform_index_tasks)
  DatabaseCleaner.strategy = example.metadata[:js] ? :truncation : :transaction
  DatabaseCleaner.start
end

config.after(:each) do |example|
  if example.metadata[:js]
    Capybara.reset_sessions!  # reset browser BEFORE slow re-seeding (LIFO hook order)
  end
  DatabaseCleaner.clean
  if example.metadata[:js]
    # Stub Solr during re-seeding so IndexAfterUpdate on Source doesn't
    # hit stale connections. Solr state stays valid because TRUNCATE resets
    # AUTO_INCREMENT so re-seeded records get the same IDs.
    sunspot_session = Sunspot.session
    Sunspot.session = Sunspot::Rails::StubSessionProxy.new(sunspot_session)
    ActiveRecord::Base.connection.execute('SET FOREIGN_KEY_CHECKS=0')
    begin
      SDBMSS::SeedData.create
      SDBMSS::ReferenceData.create_all
      SDBMSS::Mysql.create_functions
    ensure
      Sunspot.session = sunspot_session
      ActiveRecord::Base.connection.execute('SET FOREIGN_KEY_CHECKS=1')
    end
  end
end
```

## Key concepts for future reference

- **`ThreadLocalSessionProxy`**: Sunspot's default session type. Stores one Solr `Session` per thread in `Thread.current[:"sunspot_session_#{object_id}"]`. Building a new proxy (new `object_id`) causes all threads to lazily create fresh sessions on next use — this is how we get clean connections between tests.

- **`StubSessionProxy`**: A single shared (not ThreadLocal) no-op instance. When set as `Sunspot.session`, ALL threads hit the stub. Useful for re-seeding where you want to suppress all Solr operations across threads.

- **`allow_any_instance_of(User).to receive(:perform_index_tasks)`**: Patches the User class at the Ruby class level, not thread-locally. WEBrick's thread is running the same Ruby process, so it sees the patched method. RSpec tears down the patch automatically after each example.

- **LIFO hook order**: RSpec runs `after(:each)` hooks in reverse registration order. `capybara/rails` registers a cleanup hook early; our hook in `rails_helper` is registered later. So our hook runs _first_. `Capybara.reset_sessions!` at the start of our hook prevents Capybara's hook from finding an idle/dead browser.

- **AUTO_INCREMENT and TRUNCATE**: MySQL's `TRUNCATE TABLE` resets the `AUTO_INCREMENT` counter to 1. `DELETE FROM table` does not. This is why the re-seeding strategy preserves Solr index validity: the same record IDs are reused, so Solr's existing index entries remain correct.
