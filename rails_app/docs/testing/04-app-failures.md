# Phase 4 — App Failures

**Goal:** Investigate and fix failures that require understanding actual
application behavior. These are not test infrastructure problems.

Do phase 2 first. Several failures in this list may resolve once data isolation
is correct, and those that remain will be easier to characterize cleanly.

Each item here needs investigation before a fix can be prescribed — the root
cause is not yet known. The characterization data gives symptoms, not causes.

---

## Missing partials

Multiple failing data entry tests show the following text in the rendered page:

```
Missing Partial Page: "Source Overview"
Missing Partial Page: "Entry Instructions"
```

This appears in the page body rather than as a Rails error, which suggests the
app is catching the missing partial and rendering a placeholder. These partials
are referenced somewhere in the view layer but are not rendering.

**Investigate:**
- Where are these partials expected to live?
- Do they exist on disk? (`find . -name "_source_overview*"`, `find . -name "_entry_instructions*"`)
- Is there a conditional that controls whether they render?
- Are they related to the in-progress upgrade work?

Failures likely caused by this: FAILEDs 9–15 (data entry source/entry saves),
and potentially others that share the same entry form.

---

## Paper trail — entire group failing (FAILEDs 29–38)

All 10 paper trail tests are failing. No failure type was recorded in the
characterization data. The entire `spec/features/paper_trail_spec.rb` group
fails as a unit, which suggests either:

- A shared setup problem in the spec's `before` block
- A route or controller change that the spec navigates to but no longer exists
- A data dependency that is not being met

**Investigate:**
- Run `bundle exec rspec spec/features/paper_trail_spec.rb` in isolation and
  read the actual error output — the characterization data does not include it
- Check whether the routes the spec visits still exist (`rails routes | grep paper_trail`)
- Read the `before` block for what state it assumes

---

## Manage pages search failures

Several manage pages have failing search tests:

- `Manage languages` — "should do search for Language" (FAILED 22); characterization
  notes the search appears to work when tested manually
- `Manage places` — "should do search for Place" (FAILED 25)
- `Manage sources` — "should search for Sources" (FAILED 26), "should perform a
  search with multiple values" (FAILED 27), "should create a new Source" (FAILED 28)
- `Manage entries` — "should return JSON results successfully" (FAILED 19; this
  is also a request spec candidate — see phase 3), "should perform a search on
  any field without error" (FAILED 20)

The languages failure is particularly interesting: the characterization notes
say the search works manually but fails in the test. This is either a timing
issue (phase 2) or the test is checking something that has genuinely changed
(e.g. the number of search field options).

**`Manage entries` — "should perform a search on any field without error"**
This test asserts exactly 42 options in the `search_field` dropdown. If it is
failing, the actual count differs from 42. Do not change the assertion to match
an incorrect count — investigate why the count changed and whether that is
intentional.

**Investigate each:**
- Run the spec file in isolation and read the error
- Manually exercise the feature to confirm it works at all
- Compare what the test expects against what the page actually renders

---

## Login — "should disallow login" (FAILED 18)

The test expects the page to contain `'Your account has been de-activated.'`
after a login attempt with an inactive user. The characterization notes that
login is indeed disallowed, but the expected text does not appear on the page.

**Investigate:**
- What text does the page actually show after a failed login for an inactive user?
- Has the flash message text changed?
- Is the flash message being displayed at all, or is it lost in a redirect?

---

## Browse Dericci Records — add/remove verified link (FAILEDs 17, and intermittent)

Characterization notes: "When I inspect the elements on the page they don't seem
to have names that correspond to the test." The actions work manually but the
test cannot find the elements.

**Investigate:**
- What element names/IDs does the test look for?
- What does the current DOM actually render for this feature?
- Has the markup changed? Check git blame on the relevant view.

---

## "warn when editing Entry to have same catalog number" (FAILED 7)

The test expects the text `"Warning! An entry with that catalog number may already exist"`.
The characterization notes that changing the catalog number does not produce this
warning.

**Investigate:**
- Does this warning feature still exist in the application?
- Is it triggered by JS? If so, is the JS loading correctly?
- What does the page actually show after editing the catalog number?

---

## De Ricci Game — "should allow you to continue a game previously started" (FAILED 16)

Characterization notes: "When I look at the screenshot created by the test, it's
missing most of the HTML page that it's expecting to see." This may be the same
missing partial issue as the data entry failures, or it may be a DatabaseCleaner
problem where required data was truncated.

**Investigate:**
- Run in isolation and check whether the game data exists when the test runs
- Check whether any partials referenced by the game view are missing

---

## "should successfully create a manuscript record for an unlinked entry" (FAILED 15)

Characterization notes: "Database cleaner has removed referenced page containing
expected content from the test database; test should be changed so that it doesn't
depend on pages database table."

This is a data isolation issue, but the fix is in the test: the test relies on
a record in the `pages` table that gets truncated. After phase 2, if the test
still fails, add a `before` block that seeds the required page record using a
factory or direct creation — do not rely on suite-level seed data for this.

---

## Sign up — "should allow sign up" (FAILED 42)

No failure type was recorded. Run in isolation and read the error.

---

## SparqlController — ThreadError (FAILED 1)

Error: `ThreadError: already initialized`. The characterization data links to
[rails/rails#34790](https://github.com/rails/rails/issues/34790).

Read the linked issue and apply the relevant fix or workaround. This is also a
candidate for migration to a request spec (see phase 3), which may sidestep the
threading issue entirely.

---

## User Activity — "should create a new name and show it in the activity" (FAILED 43)

Characterization notes: "able to see the page and add info but it does not save."

**Investigate:**
- Is this a timing issue (JS form submission not completing before the assertion)?
- Is there a form validation error preventing the save?
- Does it pass in isolation?
