# Phase 3 — Test Quality

**Goal:** Tests live at the right layer, test what they claim to test, and don't
depend on external services at runtime. This phase can proceed in parallel with
phase 4.

The guiding principle: feature specs (Capybara, full browser) should be reserved
for tests that exercise user behavior through a UI. Any test that can be expressed
at a lower layer should be. Fewer feature specs means a faster, more reliable suite.

---

## Spec type migrations

### Move to request specs

These tests are currently feature specs but make no meaningful use of the browser.
They test HTTP behavior — response codes, JSON payloads, redirects — which is
exactly what request specs are for. Request specs are faster, more direct, and
not subject to Capybara timing issues.

**`spec/features/search_spec.rb` — "should load show Entry page (json format)"**

```ruby
# current (feature spec, js: false)
it "should load show Entry page (json format)", js: false do
  entry = Entry.last
  visit entry_path(entry, format: :json)
  data = JSON.parse(page.source)
  expect(data["id"]).to eq(entry.id)
end
```

Move to a request spec:

```ruby
# spec/requests/entries_spec.rb
it "returns entry as JSON" do
  entry = Entry.last
  get entry_path(entry, format: :json)
  data = JSON.parse(response.body)
  expect(data["id"]).to eq(entry.id)
end
```

**`spec/features/manage_entries_spec.rb` — "should return JSON results successfully"**

```ruby
# current (feature spec, js: false)
it "should return JSON results successfully", js: false do
  visit entries_path(format: :json)
  data = JSON.parse(page.source)
  expect(data['error']).to be_nil
end
```

Move to a request spec:

```ruby
# spec/requests/entries_spec.rb
it "returns entries JSON without error" do
  get entries_path(format: :json)
  data = JSON.parse(response.body)
  expect(data['error']).to be_nil
end
```

**`spec/features/manage_languages_spec.rb` — "should do search for Language"**

```ruby
# current (feature spec, js: false)
it "should do search for Language", js: false do
  # ...
  visit search_languages_path(name: "something", format: "json")
  response = JSON.parse(page.source)
  expect(response["total"]).to eq(4)
end
```

Visits a JSON search endpoint and parses `page.source`. No browser behavior. Move to
a request spec in `spec/requests/languages_spec.rb`.

**`spec/features/manage_places_spec.rb` — "should do search for Place"**

```ruby
# current (feature spec, js: false)
it "should do search for Place", js: false do
  # ...
  visit search_places_path(name: "something", format: "json")
  response = JSON.parse(page.source)
  expect(response["total"]).to eq(4)
end
```

Same pattern as the language search test above. Move to `spec/requests/places_spec.rb`.

**`spec/features/login_spec.rb` — "should allow login_as" and "should disallow login_as"**

Both tests call `visit` and then check only `page.status_code`. No UI interaction.

```ruby
# current
it "should allow login_as" do
  login(@admin, 'somethingunguessable')
  visit login_as_path username: @user_active.username
  expect(page.status_code).to eq(200)
end

it "should disallow login_as" do
  login(@user_active, 'somethingunguessable')
  visit login_as_path username: @admin.username
  expect(page.status_code).to eq(403)
end
```

Move to request specs that set auth headers directly rather than going through
the login UI.

**`spec/controllers/sparql_controller_spec.rb`**

Controller specs (`spec/controllers/`) are deprecated in favor of request specs
as of Rails 5. This is the only controller spec in the suite and it is currently
failing. Migrate to `spec/requests/sparql_spec.rb`:

```ruby
# spec/requests/sparql_spec.rb
describe "GET /sparql" do
  it "returns http success" do
    get sparql_index_path
    expect(response).to have_http_status(:success)
  end
end
```

---

## Duplicate descriptions

**`spec/features/manage_languages_spec.rb` — "should show list of Languages" × 2**

Two contexts both named `"when admin is logged in"` each contain `it "should show list
of Languages"`. They are not the same test: the first checks for a "Martian" language
created in the outer `before :all`, the second checks for "Pig Latin" created in a
nested `before :all`. Give them distinct descriptions so failures are unambiguous:

```ruby
# first context
it "should show list of Languages including unreviewed ones" do ...

# second context
it "should show list of Languages created by admin" do ...
```

Also rename both contexts so they are distinguishable (currently both are
`context "when admin is logged in"`).

**`spec/features/manage_sources_spec.rb` — "should perform a search with multiple values for the same field" × 2**

Two examples share an identical description. They test different behavior:

- First (line 37): submits a multi-value search for Morgan + Libreria with no assertion
  on results. Rename: `"should perform a multi-value search without error"`.
- Second (line 54): submits a multi-value search and asserts the known source is found.
  Rename: `"should return expected results for a multi-value search"`.

Until renamed, the test runner reports both under the same name, making failures
impossible to distinguish in CI output.

---

## External dependencies — VIAF

The two VIAF tests (`gets data`, `does autosuggest`) make live HTTP calls to an
external service. This makes them slow, non-deterministic, and broken in
network-restricted environments.

Fix with VCR:

1. Add `vcr` and `webmock` to the test group in `Gemfile`
2. Configure VCR in `spec/spec_helper.rb` or a dedicated `spec/support/vcr.rb`
3. Record cassettes against the real VIAF endpoint once:
   ```bash
   VCR_RECORD=new_episodes bundle exec rspec spec/lib/viaf_spec.rb
   ```
4. Commit the cassette files — future runs replay them, no network needed
5. Remove `:known_failure` from the two VIAF tests

---

## `before :all` audit

Several feature specs use `before :all` blocks that share mutable state across
examples. Any test that mutates an instance variable set in `before :all` creates
an order dependency for all subsequent examples in that group.

Review each file for `before :all` usage. For each:
- If the setup is expensive (e.g. seeding reference data), keep `before :all`
  but ensure no example mutates the shared objects
- If the setup is cheap (factory creation, login), convert to `before :each`

Known issue: `manage_entries_spec.rb` references `@user` before assigning it in
the same `before :all` block (line 13 uses `@user`, line 17 assigns it). This
means `@unapproved_entry` is created with `created_by: nil`. Fix the ordering.
