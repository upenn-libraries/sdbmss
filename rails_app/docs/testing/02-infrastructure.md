# Phase 2 — Test Infrastructure

**Goal:** Each test starts from a known database state. Capybara waits correctly
for JS. Do this before drawing conclusions about what is still broken — data
isolation issues are masking an unknown number of failures.

---

## DatabaseCleaner

### The problem

`rails_helper.rb` calls `DatabaseCleaner.clean` once at suite boot and never
again. With `use_transactional_fixtures = false`, every test that writes to the
database leaves dirty state for all subsequent tests. The current code:

```ruby
# rails_helper.rb — current (broken)
DatabaseCleaner.strategy = :truncation
DatabaseCleaner.start
DatabaseCleaner.clean          # runs once at boot, never again
SDBMSS::SeedData.create
SDBMSS::ReferenceData.create_all
SDBMSS::Mysql.create_functions
config.before(:all) do
end                            # empty — no per-example cleanup
```

The comment citing Poltergeist as the reason for `use_transactional_fixtures = false`
is stale — the project now uses Cuprite, which does not have this constraint.

### The fix

The standard pattern for Capybara + DatabaseCleaner is:

- `:transaction` strategy for non-JS tests — fast, automatic rollback, no cleanup needed
- `:truncation` strategy for JS tests — the browser runs in a separate thread and
  cannot share a database transaction

```ruby
# rails_helper.rb — target state
config.use_transactional_fixtures = false

config.before(:suite) do
  DatabaseCleaner.clean_with(:truncation)
  SDBMSS::SeedData.create
  SDBMSS::ReferenceData.create_all
  SDBMSS::Mysql.create_functions
end

config.before(:each) do |example|
  DatabaseCleaner.strategy = example.metadata[:js] ? :truncation : :transaction
  DatabaseCleaner.start
end

config.after(:each) do
  DatabaseCleaner.clean
end
```

### Seed data after truncation

The suite currently seeds data once at boot. With per-example truncation for JS
tests, that data will be wiped. Two options:

1. **Re-seed in `before(:suite)` only** and accept that JS tests run against a
   potentially clean database — tests that need seed data must set it up in their
   own `before` blocks using factories
2. **Re-seed after each truncation** in `after(:each)` — simpler in the short term
   but slow; acceptable while fixing other problems

Start with option 2 to unblock other work, migrate to option 1 over time.

### Steps

1. Update `rails_helper.rb` with the `before(:suite)` / `before(:each)` /
   `after(:each)` pattern above
2. Re-enable random order in `spec_helper.rb` (`config.order = :random` is
   currently commented out) — this will surface any remaining order dependencies
3. Run `bundle exec rspec --tag ~known_failure` and confirm still green
4. Run `bundle exec rspec --tag known_failure` and note which previously-failing
   tests now pass — remove their `:known_failure` tags

---

## Capybara timing

### The problem

Multiple tests fail with `Capybara::ElementNotFound` because they attempt to
interact with elements before JS has rendered them. The current pattern:

```ruby
find_by_id("delete_title_0").click   # fails if element not yet in DOM
fill_in 'title_0', with: ''          # fails if field not yet rendered
```

The correct pattern is to assert the element is present first using a
`have_*` matcher, which uses Capybara's built-in wait:

```ruby
expect(page).to have_css("#delete_title_0")
find_by_id("delete_title_0").click

expect(page).to have_field('title_0')
fill_in 'title_0', with: ''
```

### Known timing failures (from characterization data)

Each of these is a `Capybara::ElementNotFound` — the fix pattern is the same in
each case: add a `have_*` wait before the interaction.

| File | Element not found | Test |
|------|-------------------|------|
| `spec/features/data_edit_spec.rb:214` | `delete_title_0` | should remove a title on Edit page |
| `spec/features/data_edit_spec.rb:243` | `title_0` field | should clear out a title on Edit Page |
| `spec/features/data_edit_spec.rb:267` | `author_observed_name_0` field | should clear out a Name Authority field |
| `spec/features/data_entry_spec.rb:136` | `title` field | should find source by title on Select Source page |
| `spec/features/data_entry_spec.rb:119` | `agent` field | should find source by agent on Select Source page |
| `spec/features/data_entry_spec.rb:145` | `title` field | should NOT find source by title on Select Source page |

### `sleep` calls to replace

The suite contains hard sleeps that should be replaced with Capybara waits.
`sleep` makes tests slow and still leaves them racy on slower machines.

| File | Line | Sleep | Replace with |
|------|------|-------|-------------|
| `spec/features/manage_entries_spec.rb` | ~41 | `sleep 1.1` | `expect(page).not_to have_selector("#spinner", visible: true)` (already present on next line — remove the sleep) |
| `spec/features/manage_entries_spec.rb` | ~64 | `sleep 1.1` | wait for the expected content to appear |
| `spec/features/manage_entries_spec.rb` | ~95 | `sleep 1.1` | wait for row count to change |
| `spec/features/manage_entries_spec.rb` | ~109 | `sleep(1)` | `expect(page).to have_content("Entry marked as deprecated.")` |
| `spec/features/search_spec.rb` | ~162, ~175 | `sleep 2` (×2) | wait for `#search_results_info` to update |

### `default_max_wait_time`

`spec_helper.rb` sets `Capybara.default_max_wait_time = 8`. This may be
insufficient for the Docker environment on slower machines. If timing failures
persist after replacing sleeps with `have_*` waits, raise this to 10 or 15.

---

## Setup in test bodies

### The problem

Several feature spec files put data setup inside `it` blocks rather than `before`
hooks. This creates implicit chains where later tests in the file only work because an
earlier test ran first as a side effect.

The clearest examples are `paper_trail_spec.rb` and `data_edit_spec.rb`, which both
include `DataEntryHelpers` and call `create_entry` inside the first `it` block:

```ruby
# paper_trail_spec.rb
it 'should load the history page successfully', :known_failure do
  create_entry          # ← creates an Entry as a side effect of this test
  e = Entry.last
  visit history_entry_path(e)
  ...
end

it "should register changes in the entry basic fields", :known_failure do
  e = Entry.last        # ← silently depends on the entry created above
  visit edit_entry_path(e)
  ...
end
```

All 9 subsequent tests in `paper_trail_spec.rb` follow this pattern. So does `data_edit_spec.rb` with its 5 downstream tests.

### The observable symptom

Running the suite with `--tag ~known_failure` produces **more** failures than running
it bare — approximately 78 vs 42. Excluding the `:known_failure` tests removes the
`create_entry` call that the rest of the chain depends on, causing those downstream
tests to fail with unexpected state or a missing entry.

Running the suite with feature specs excluded drops to ~3 failures, confirming the
problem is contained to feature specs.

### The fix

Move `create_entry` (and equivalent setup calls) from `it` bodies into `before :all`
or `before :each` hooks so setup always runs regardless of which tests are selected.

For `paper_trail_spec.rb` and `data_edit_spec.rb`, a `before :all` is appropriate
since the full-browser `create_entry` is expensive and the tests genuinely form a
workflow:

```ruby
before :all do
  login(@user, 'somethingunguessable')
  create_entry
end

it 'should load the history page successfully' do  # no longer needs :known_failure
  e = Entry.last
  visit history_entry_path(e)
  ...
end
```

Once the entry creation is in the hook, the first test in each chain becomes a real
test rather than a setup vehicle, and `:known_failure` can be removed from it if it
actually passes.

### Known chains

| File | Setup call | Tests in chain |
|------|-----------|----------------|
| `spec/features/paper_trail_spec.rb` | `create_entry` in first `it` | 9 subsequent tests use `Entry.last` |
| `spec/features/data_edit_spec.rb` | `create_entry` in first `it` | 5 subsequent tests use `Entry.last` |

---

## `before :all` vs `before :each`

Several specs use `before :all` for setup, including `manage_entries_spec.rb`.
Instance variables set in `before :all` are shared across all examples — any
test that mutates them affects subsequent tests. With `use_transactional_fixtures = false`
and no per-example cleanup, this compounds the data isolation problem.

Additionally, `manage_entries_spec.rb` has a bug in its `before :all` block:
`@user` is referenced on line 13 (as `created_by: @user`) but not assigned until
line 17. The `@unapproved_entry` is therefore created with `created_by: nil`.

Review all `before :all` blocks in the feature suite and determine whether they
should be `before :each`, or whether the setup genuinely needs to run once.
