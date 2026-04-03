# Phase 2 — Test Infrastructure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix database isolation, Capybara timing, and test-ordering fragility so that `bundle exec rspec --tag ~known_failure` produces a stable, trustworthy green run.

**Architecture:** Four independent problems are addressed in sequence: (1) DatabaseCleaner wired up per-example, (2) RSpec random order re-enabled, (3) setup-in-test-body chains moved to `before :all`, (4) hard sleeps replaced with Capybara waits. Each task is an isolated file edit; later tasks depend on earlier ones only for the final verification step.

**Tech Stack:** RSpec, DatabaseCleaner, Capybara + Cuprite, Sunspot/Solr

**Spec reference:** `docs/testing/02-infrastructure.md`

---

## Files modified

| File | What changes |
|------|-------------|
| `spec/rails_helper.rb` | Replace broken one-shot DatabaseCleaner with `before(:suite)` / `before(:each)` / `after(:each)` pattern |
| `spec/spec_helper.rb` | Re-enable `config.order = :random`; raise `default_max_wait_time` |
| `spec/features/manage_entries_spec.rb` | Fix `@user` assigned after use in `before :all`; replace 4 hard sleeps |
| `spec/features/paper_trail_spec.rb` | Move `create_entry` from first `it` into `before :all` |
| `spec/features/data_edit_spec.rb` | Move `create_entry` from first `it` into `before :all`; add 3 Capybara waits |
| `spec/features/data_entry_spec.rb` | Add Capybara waits before field interactions; replace 2 hard sleeps |
| `spec/features/search_spec.rb` | Remove redundant `sleep(0.5)` after `wait_for_solr_to_be_current` |

---

## Task 1: Fix DatabaseCleaner in `rails_helper.rb`

**Files:**
- Modify: `spec/rails_helper.rb:79-87`

The current code calls `DatabaseCleaner.clean` once at boot and never again. Replace those 9 lines (the bare cleaner calls + empty `before(:all)`) with proper suite/example hooks.

- [ ] **Step 1: Read the current state**

Open `spec/rails_helper.rb`. Confirm lines 79-87 look like:

```ruby
DatabaseCleaner.strategy = :truncation
DatabaseCleaner.start
DatabaseCleaner.clean
Sunspot::remove_all!
SDBMSS::SeedData.create
SDBMSS::ReferenceData.create_all
SDBMSS::Mysql.create_functions
config.before(:all) do
end
```

- [ ] **Step 2: Replace the broken setup**

Replace those 9 lines with:

```ruby
config.before(:suite) do
  DatabaseCleaner.clean_with(:truncation)
  Sunspot::remove_all!
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
  if RSpec.current_example.metadata[:js]
    SDBMSS::SeedData.create
    SDBMSS::ReferenceData.create_all
    SDBMSS::Mysql.create_functions
  end
end
```

- [ ] **Step 3: Verify file is syntactically valid**

```bash
docker compose exec app bundle exec ruby -c spec/rails_helper.rb
```

Expected: `Syntax OK`

- [ ] **Step 4: Commit**

```bash
git add spec/rails_helper.rb
git commit -m "fix: wire up DatabaseCleaner per-example with truncation for JS tests"
```

---

## Task 2: Re-enable random order in `spec_helper.rb`

**Files:**
- Modify: `spec/spec_helper.rb`

`config.order = :random` is inside a `=begin`/`=end` block (lines 68–109) and never runs. Extract just that line and place it outside the block.

- [ ] **Step 1: Read spec_helper.rb**

Confirm `config.order = :random` is at roughly line 102 inside the `=begin`/`=end` block.

- [ ] **Step 2: Add the line after `=end`**

After the `=end` on line ~109 and before the closing `end` of `RSpec.configure`, add:

```ruby
  config.order = :random
  Kernel.srand config.seed
```

(Keep the `=begin`/`=end` block as-is — don't delete it. Adding outside is cleaner than editing inside.)

- [ ] **Step 3: Verify syntax**

```bash
docker compose exec app bundle exec ruby -c spec/spec_helper.rb
```

Expected: `Syntax OK`

- [ ] **Step 4: Commit**

```bash
git add spec/spec_helper.rb
git commit -m "fix: re-enable random test order to surface order dependencies"
```

---

## Task 3: Fix `@user` ordering bug in `manage_entries_spec.rb`

**Files:**
- Modify: `spec/features/manage_entries_spec.rb:6-19`

`@unapproved_entry` is created on line 9 with `created_by: @user`, but `@user` is not assigned until line 17. The entry always has `created_by: nil`.

- [ ] **Step 1: Read the current `before :all` block**

Lines 6-19 currently read:

```ruby
before :all do
  @unapproved_entry = Entry.new(
    source: Source.last,
    created_by: @user,      # @user is nil here
    folios: 15,
  )
  @unapproved_entry.save!

  SDBMSS::Util.wait_for_solr_to_be_current

  @user = User.where(role: "admin").first   # assigned too late
end
```

- [ ] **Step 2: Move `@user` assignment to the top**

Replace the `before :all` block with:

```ruby
before :all do
  @user = User.where(role: "admin").first

  @unapproved_entry = Entry.new(
    source: Source.last,
    created_by: @user,
    folios: 15,
  )
  @unapproved_entry.save!

  SDBMSS::Util.wait_for_solr_to_be_current
end
```

- [ ] **Step 3: Verify syntax**

```bash
docker compose exec app bundle exec ruby -c spec/features/manage_entries_spec.rb
```

Expected: `Syntax OK`

- [ ] **Step 4: Commit**

```bash
git add spec/features/manage_entries_spec.rb
git commit -m "fix: assign @user before using it in manage_entries_spec before :all"
```

---

## Task 4: Fix setup chain in `paper_trail_spec.rb`

**Files:**
- Modify: `spec/features/paper_trail_spec.rb`

The first `it` block (line 51) calls `create_entry` as a side effect. When that test is excluded via `--tag ~known_failure`, the 9 subsequent tests that call `Entry.last` get wrong data. Moving `create_entry` to `before :all` inside the context ensures setup runs regardless of tag filters.

- [ ] **Step 1: Read the current context block**

In `spec/features/paper_trail_spec.rb`, inside `context "when user is logged in"`, the current structure is:

```ruby
before :each do
  login(@user, 'somethingunguessable')
end

after :each do
  page.reset!
end

require "lib/data_entry_helpers"
include DataEntryHelpers

describe '(for simple changes)' do
  it 'should load the history page successfully', :known_failure do
    create_entry          # ← setup disguised as a test
    e = Entry.last
    visit history_entry_path(e)
    expect(page).to have_content("History of changes to #{e.public_id}")
  end
  ...
```

- [ ] **Step 2: Add `before :all` for entry creation**

Directly inside `context "when user is logged in"`, after the `include DataEntryHelpers` line and before the `describe '(for simple changes)'` block, add:

```ruby
before :all do
  login(@user, 'somethingunguessable')
  create_entry
end
```

- [ ] **Step 3: Edit the first `it` block**

Change the first `it` from:

```ruby
it 'should load the history page successfully', :known_failure do
  create_entry

  e = Entry.last

  visit history_entry_path (e)

  expect(page).to have_content("History of changes to #{e.public_id}")
end
```

to:

```ruby
it 'should load the history page successfully' do
  e = Entry.last

  visit history_entry_path(e)

  expect(page).to have_content("History of changes to #{e.public_id}")
end
```

(Removed `create_entry` call and `:known_failure` tag.)

- [ ] **Step 4: Verify syntax**

```bash
docker compose exec app bundle exec ruby -c spec/features/paper_trail_spec.rb
```

Expected: `Syntax OK`

- [ ] **Step 5: Commit**

```bash
git add spec/features/paper_trail_spec.rb
git commit -m "fix: move create_entry to before :all in paper_trail_spec to break ordering dependency"
```

---

## Task 5: Fix setup chain in `data_edit_spec.rb`

**Files:**
- Modify: `spec/features/data_edit_spec.rb`

Same pattern as Task 4. The "should show creator on Edit page" test (line 141) calls `create_entry`; 5 subsequent tests use `Entry.last` assuming it ran.

- [ ] **Step 1: Read the current context block**

In `spec/features/data_edit_spec.rb`, inside `context "when user is logged in"`, the current structure includes:

```ruby
before :each do
  login(@user, 'somethingunguessable')
end

after :each do
  page.reset!
end

require "lib/data_entry_helpers"
include DataEntryHelpers

it "should edit an existing Source" do
  ...
end

it "should show creator on Edit page", :known_failure do
  create_entry             # ← setup disguised as a test
  entry = Entry.last
  visit edit_entry_path :id => entry.id
  expect(page).to have_content "About This Entry Record"
  expect(page).to have_content "by #{entry.created_by.username}"
end
```

- [ ] **Step 2: Add `before :all` for entry creation**

Directly inside `context "when user is logged in"`, after the `include DataEntryHelpers` line, add:

```ruby
before :all do
  login(@user, 'somethingunguessable')
  create_entry
end
```

- [ ] **Step 3: Edit the first chained `it` block**

Change:

```ruby
it "should show creator on Edit page", :known_failure do
  create_entry

  entry = Entry.last

  visit edit_entry_path :id => entry.id

  expect(page).to have_content "About This Entry Record"
  expect(page).to have_content "by #{entry.created_by.username}"
end
```

to:

```ruby
it "should show creator on Edit page" do
  entry = Entry.last

  visit edit_entry_path :id => entry.id

  expect(page).to have_content "About This Entry Record"
  expect(page).to have_content "by #{entry.created_by.username}"
end
```

- [ ] **Step 4: Verify syntax**

```bash
docker compose exec app bundle exec ruby -c spec/features/data_edit_spec.rb
```

Expected: `Syntax OK`

- [ ] **Step 5: Commit**

```bash
git add spec/features/data_edit_spec.rb
git commit -m "fix: move create_entry to before :all in data_edit_spec to break ordering dependency"
```

---

## Task 6: Fix Capybara timing failures in `data_edit_spec.rb`

**Files:**
- Modify: `spec/features/data_edit_spec.rb` — three `it` blocks

Each failure is a `Capybara::ElementNotFound` because the code interacts with an element before JS has rendered it. Pattern: add a `have_*` assertion immediately before the interaction so Capybara waits for the element.

- [ ] **Step 1: Fix "should remove a title on Edit page" (~line 200)**

Current:
```ruby
find_by_id("delete_title_0").click
```

Change to:
```ruby
expect(page).to have_css("#delete_title_0")
find_by_id("delete_title_0").click
```

- [ ] **Step 2: Fix "should clear out a title on Edit Page" (~line 230)**

Current:
```ruby
fill_in 'title_0', with: ''
```

Change to:
```ruby
expect(page).to have_field('title_0')
fill_in 'title_0', with: ''
```

- [ ] **Step 3: Fix "should clear out a Name Authority (autocomplete) field" (~line 256)**

Current:
```ruby
fill_in 'author_observed_name_0', with: "Joe"
```

Change to:
```ruby
expect(page).to have_field('author_observed_name_0')
fill_in 'author_observed_name_0', with: "Joe"
```

- [ ] **Step 4: Verify syntax**

```bash
docker compose exec app bundle exec ruby -c spec/features/data_edit_spec.rb
```

Expected: `Syntax OK`

- [ ] **Step 5: Commit**

```bash
git add spec/features/data_edit_spec.rb
git commit -m "fix: add Capybara have_* waits before element interactions in data_edit_spec"
```

---

## Task 7: Fix Capybara timing in `data_entry_spec.rb` (source search tests)

**Files:**
- Modify: `spec/features/data_entry_spec.rb` — four `it` blocks in the "Select Source page" tests

After clicking `#select_source`, the source-search form is rendered by JS. Without a wait, `fill_in 'agent'` / `fill_in 'title'` fires before the field exists.

- [ ] **Step 1: Fix "should find source by agent on Select Source page" (~line 116)**

Current:
```ruby
visit new_entry_path
find('#select_source').click
fill_in 'agent', :with => 'Soth'
```

Change to:
```ruby
visit new_entry_path
find('#select_source').click
expect(page).to have_field('agent')
fill_in 'agent', :with => 'Soth'
```

- [ ] **Step 2: Fix "should NOT find source by agent on Select Source page" (~line 125)**

Current:
```ruby
visit new_entry_path
find('#select_source').click
fill_in 'agent', :with => 'Nonexistent'
sleep 1.5
expect(page).to have_content "No source found matching your criteria."
```

Change to:
```ruby
visit new_entry_path
find('#select_source').click
expect(page).to have_field('agent')
fill_in 'agent', :with => 'Nonexistent'
expect(page).to have_content "No source found matching your criteria."
```

- [ ] **Step 3: Fix "should find source by title on Select Source page" (~line 133)**

Current:
```ruby
visit new_entry_path
find('#select_source').click
fill_in 'title', :with => 'uniq'
```

Change to:
```ruby
visit new_entry_path
find('#select_source').click
expect(page).to have_field('title')
fill_in 'title', :with => 'uniq'
```

- [ ] **Step 4: Fix "should NOT find source by title on Select Source page" (~line 142)**

Current:
```ruby
visit new_entry_path
find('#select_source').click
fill_in 'title', :with => 'nonexistentjunk'
sleep 0.5
expect(page).to have_content "No source found matching your criteria."
```

Change to:
```ruby
visit new_entry_path
find('#select_source').click
expect(page).to have_field('title')
fill_in 'title', :with => 'nonexistentjunk'
expect(page).to have_content "No source found matching your criteria."
```

- [ ] **Step 5: Verify syntax**

```bash
docker compose exec app bundle exec ruby -c spec/features/data_entry_spec.rb
```

Expected: `Syntax OK`

- [ ] **Step 6: Commit**

```bash
git add spec/features/data_entry_spec.rb
git commit -m "fix: add Capybara field waits and remove sleeps in data_entry_spec source search tests"
```

---

## Task 8: Replace sleep calls in `manage_entries_spec.rb`

**Files:**
- Modify: `spec/features/manage_entries_spec.rb` — lines 41, 65, 94, 109, 152, 166, 191, 205

- [ ] **Step 1: Fix "should search" test (~line 41)**

Current:
```ruby
find('#search_submit').click()
sleep 1.1
expect(page).not_to have_selector("#spinner", visible: true)
```

Change to (remove sleep — `not_to have_selector` already uses Capybara's wait):
```ruby
find('#search_submit').click()
expect(page).not_to have_selector("#spinner", visible: true)
```

- [ ] **Step 2: Fix "should mark entry as approved" test (~line 65)**

Current:
```ruby
find('#search_submit').click()

sleep 1.1

expect(page).to have_selector("#select-all", visible: true)
```

Change to:
```ruby
find('#search_submit').click()

expect(page).to have_selector("#select-all", visible: true)
```

- [ ] **Step 3: Fix "should delete an entry" test (~line 94)**

Current:
```ruby
click_button "Yes"
sleep 1.1

expect(Entry.all.count).to eq(count - 1)
```

The entry ID needs to be captured before deletion so we can wait for its UI row to disappear. First, change the test to capture the entry:

```ruby
it "should delete an entry" do
  entry_to_delete = Entry.last
  count = Entry.all.count

  # mock out the confirm dialogue
  page.evaluate_script('window.confirm = function() { return true; }')

  visit entries_path
  find("#delete_#{entry_to_delete.id}", match: :first).trigger("click")
  expect(page).to have_content("Are you sure you want to delete entry")
  click_button "Yes"
  expect(page).not_to have_css("#delete_#{entry_to_delete.id}")

  expect(Entry.all.count).to eq(count - 1)
end
```

- [ ] **Step 4: Fix "should mark entry as deprecated" test (~line 109)**

Current:
```ruby
find("#deprecate").click
sleep(1)
expect(page).to have_content("Entry marked as deprecated.")
```

Change to:
```ruby
find("#deprecate").click
expect(page).to have_content("Entry marked as deprecated.")
```

- [ ] **Step 5: Fix multiple-value search tests — all four `sleep 2` occurrences (~lines 152, 166, 191, 205)**

Each occurrence looks like:
```ruby
find('#search_submit').click()

sleep 2

count = page.find('#search_results_info').text.match(/of\s([\d,]+)\s/)[1].gsub(",", "").to_i
```

Change each to:
```ruby
find('#search_submit').click()

expect(page).to have_selector('#search_results_info', text: /of\s[\d,]+/)
count = page.find('#search_results_info').text.match(/of\s([\d,]+)\s/)[1].gsub(",", "").to_i
```

There are four such occurrences — two in "should perform a search with multiple values for the same field (AND)" and two in "(ANY)". Change all four.

- [ ] **Step 6: Verify syntax**

```bash
docker compose exec app bundle exec ruby -c spec/features/manage_entries_spec.rb
```

Expected: `Syntax OK`

- [ ] **Step 7: Commit**

```bash
git add spec/features/manage_entries_spec.rb
git commit -m "fix: replace hard sleeps with Capybara waits in manage_entries_spec"
```

---

## Task 9: Remove redundant sleep in `search_spec.rb`

**Files:**
- Modify: `spec/features/search_spec.rb:161`

`sleep(0.5)` appears right after `SDBMSS::Util.wait_for_solr_to_be_current`, which already handles the Solr timing. The sleep is redundant.

- [ ] **Step 1: Find and remove the sleep**

Current (~lines 158-164):
```ruby
entry.save!
SDBMSS::Util.wait_for_solr_to_be_current

sleep(0.5)

visit entry_path(entry)
expect(page.status_code).to eq(404)
```

Change to:
```ruby
entry.save!
SDBMSS::Util.wait_for_solr_to_be_current

visit entry_path(entry)
expect(page.status_code).to eq(404)
```

- [ ] **Step 2: Verify syntax**

```bash
docker compose exec app bundle exec ruby -c spec/features/search_spec.rb
```

Expected: `Syntax OK`

- [ ] **Step 3: Commit**

```bash
git add spec/features/search_spec.rb
git commit -m "fix: remove redundant sleep after wait_for_solr_to_be_current in search_spec"
```

---

## Task 10: Raise `default_max_wait_time` in `spec_helper.rb`

**Files:**
- Modify: `spec/spec_helper.rb`

The current value of 8s may be insufficient for the Docker environment on slower machines. The doc recommends raising to 15 if timing failures persist after replacing sleeps with `have_*` waits.

- [ ] **Step 1: Update the wait time**

Current:
```ruby
Capybara.default_max_wait_time = 8
```

Change to:
```ruby
Capybara.default_max_wait_time = 15
```

- [ ] **Step 2: Verify syntax**

```bash
docker compose exec app bundle exec ruby -c spec/spec_helper.rb
```

Expected: `Syntax OK`

- [ ] **Step 3: Commit**

```bash
git add spec/spec_helper.rb
git commit -m "fix: raise Capybara default_max_wait_time to 15s for Docker environment"
```

---

## Task 11: Run verification suite

No file changes. Confirm the fixes work and identify any remaining `:known_failure` tests that can be untagged.

- [ ] **Step 1: Run non-known-failure tests**

```bash
docker compose exec app bundle exec rspec --tag ~known_failure 2>&1 | tail -20
```

Expected: All examples pass (0 failures). Note the total count.

- [ ] **Step 2: Run known-failure tests**

```bash
docker compose exec app bundle exec rspec --tag known_failure 2>&1 | tail -40
```

Note which tests now PASS. These can have their `:known_failure` tag removed.

- [ ] **Step 3: Remove `:known_failure` from newly passing tests**

For each test that passed in Step 2:
- Open the file
- Remove `, :known_failure` from the `it` line
- Run that file alone to confirm it still passes:
  ```bash
  docker compose exec app bundle exec rspec path/to/spec_file.rb:LINE_NUMBER
  ```

- [ ] **Step 4: Re-run full suite without known_failure tag**

```bash
docker compose exec app bundle exec rspec --tag ~known_failure 2>&1 | tail -20
```

Expected: Still all green after untagging.

- [ ] **Step 5: Commit any tag removals**

```bash
git add spec/
git commit -m "fix: remove :known_failure tags from tests that now pass"
```
