# Phase 1 — Tagging Known Failures

**Goal:** Quarantine failing tests so the default run is green. Tests are tagged,
not deleted. This is the current phase of work.

---

## Tagging convention

All quarantined tests get `:known_failure`. This is the only tag that controls
exclusion from a run.

`:flaky` is an optional second tag for tests that are intermittent — it is a
descriptor, but it is also filterable (see below). It is never used without
`:known_failure`.

```ruby
# Consistently broken
it "does something broken", :known_failure do

# Intermittent — may pass or fail depending on run order or timing
it "does something unreliable", :known_failure, :flaky do

# With an optional reason — enrich as we learn more, not required upfront
it "does something broken", known_failure: "missing partial, see 04-app-failures" do
```

---

## Running tagged tests manually

These are manual commands. There is no default exclusion configured in `.rspec`.

```bash
# Exclude known failures — the "working" suite
bundle exec rspec --tag ~known_failure

# Run only quarantined tests
bundle exec rspec --tag known_failure

# Run only the intermittent subset
bundle exec rspec --tag flaky

# Run everything
bundle exec rspec
```

---

## Known failures

From two characterization runs (2026-02-20 and 2026-02-25).

### Consistent failures — run 1 (45 total)

| Area | Test description | FAILED # |
|------|-----------------|----------|
| SparqlController | returns http success | 1 |
| Data entry | should show creator on Edit page | 2 |
| Data entry | should preserve entry on Edit page when saving without changes | 3 |
| Data entry | should remove a title on Edit page | 4 |
| Data entry | should clear out a title on Edit Page | 5 |
| Data entry | should clear out a Name Authority (autocomplete) field | 6 |
| Data entry | should warn when editing Entry to have same catalog number | 7 |
| Data entry | should find source by title on Select Source page | 8 |
| Data entry | should save a new Source (auction catalog) | 9 |
| Data entry | should save a new Source (other published source) | 10 |
| Data entry | should save a new Source with no date | 11 |
| Data entry | should save a new Source, filtering out invalid fields | 12 |
| Data entry | should warn about existing Source | 13 |
| Data entry | should save an auction catalog Entry | 14 |
| Data entry | should successfully create a manuscript record for an unlinked entry | 15 |
| De Ricci Game | should allow you to continue a game previously started | 16 |
| Browse Dericci Records | should allow an admin to remove verified link | 17 |
| Login | should disallow login | 18 |
| Manage entries | should return JSON results successfully | 19 |
| Manage entries | should perform a search on any field without error | 20 |
| Manage languages | should show list of Languages | 21 |
| Manage languages | should do search for Language | 22 |
| Manage languages | should show list of Languages (duplicate?) | 23 |
| Manage Names | should show merge link when new name already exists | 24 |
| Manage places | should do search for Place | 25 |
| Manage sources | should search for Sources | 26 |
| Manage sources | should perform a search with multiple values for the same field | 27 |
| Manage sources | should create a new Source | 28 |
| Paper trail (simple) | should load the history page successfully | 29 |
| Paper trail (simple) | should register changes in the entry basic fields | 30 |
| Paper trail (simple) | should present the option to revert simple changes | 31 |
| Paper trail (simple) | should successfully restore the previous version | 32 |
| Paper trail (associations) | should show a change to an association in change history | 33 |
| Paper trail (associations) | should show options to revert an 'association' change | 34 |
| Paper trail (associations) | should successfully restore the previous association | 35 |
| Paper trail (associations) | should save a 'revert' change in the record history | 36 |
| Paper trail (associations) | should recreate an associated field that was deleted | 37 |
| Paper trail (associations) | should remove an associated field that was created | 38 |
| Blacklight Search | should show my public entries | 39 |
| Blacklight Search | should load advanced search page | 40 |
| Blacklight Search | should load show Entry page (json format) | 41 |
| Sign up | should allow sign up | 42 |
| User Activity | should create a new name and show it in the activity | 43 |
| VIAF | gets data | 44 |
| VIAF | does autosuggest | 45 |

### Intermittent failures — flipped between runs (7 total)

These get both `:known_failure` and `:flaky`.

| Area | Test description |
|------|-----------------|
| Data entry | should find source by date on Select Source page |
| Data entry | should find source by title on Select Source page |
| Data entry | should find source by agent on Select Source page |
| Data entry | should NOT find source by title on Select Source page |
| Browse Dericci Records | should allow an admin to add a verified link |
| Browse Dericci Records | should allow an admin to remove verified link |
| Blacklight Search | should load show Name page |

---

## Finding additional failures

The characterization runs used a fixed test order. Some failures may only surface
with random ordering or when run against a dirty database.

```bash
# Surface order-dependent failures
bundle exec rspec --order random

# Run a single spec file in isolation to compare against suite behavior
bundle exec rspec spec/features/paper_trail_spec.rb
```

If a spec file passes in isolation but fails in the full suite, its failures are
data-isolation driven — they belong in phase 2, not here.

---

## Definition of done

- All tests in the lists above are tagged `:known_failure` (or `:known_failure, :flaky`)
- Tags are committed to version control
- `bundle exec rake spec:check_phase1` exits 0 on 3 consecutive runs

```bash
bundle exec rake spec:check_phase1
```

This task runs the full suite, collects failures, and checks that every failure
belongs to the tagged set. It prints any untagged failures and exits 1 if any are
found. Source: `lib/tasks/spec_check.rake`.

**Note: the `--tag ~known_failure` baseline is a phase 2 goal, not a phase 1 goal.**

Running `bundle exec rspec --tag ~known_failure` currently produces *more* failures
(~78) than running the suite bare (~42). The tagged tests are not just broken in
isolation — many of them create database state as a side effect of running that
downstream tests in the same file depend on. Excluding them removes that setup, causing
the downstream tests to fail too.

The affected chains are documented in `02-infrastructure.md` under
"Setup in test bodies". Phase 1 is complete when the bare run is stable and contains
only tagged failures. Phase 2 (data isolation) must be finished before
`--tag ~known_failure` can be used as a passing baseline.
