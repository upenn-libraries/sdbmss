# SDBM Phase 1 — Technical Plan

Sprint 1 starts: March 30, 2026

## Objective

Execute the first meaningful increment of modernization: upgrade Blacklight 5.1 → 6.x,
resolve breaking changes, assess and execute the highest feasible Ruby upgrade within
Rails 4.2 constraints, and produce a detailed Phase 2 roadmap.

---

## Key Decisions

### Solr / Search Layer

**Current state:** Solr 4.2.0 running as a standalone Docker service, connected via
`SOLR_URL`. Sunspot 2.2.0 is pinned because newer versions cause NullPointerExceptions.

**Critical root cause — "Entry N" ID format:** Sunspot indexes records as `"Entry 1234"`
strings while Blacklight expects numeric IDs. Multiple Blacklight patches exist solely
because of this mismatch (`fetch_one`, `url_for_document`, `SearchBuilder`). A
commented-out `EntryAdapter` in `config/initializers/sunspot.rb` was the intended proper
fix and was never activated. Any work touching Solr or Blacklight must account for this.

**Decision:** Keep Sunspot 2.2.0 for Phase 1. Solr will need to be upgraded from 4.2.0
to 8.x as part of the Blacklight 6 work (Blacklight 6 targets Solr 7/8). RSolr migration
is deferred to Phase 2.

**Phase 2 note:** Modern Blacklight (6+) uses RSolr natively. The full search layer
rewrite is a Phase 2 deliverable.

---

### Ruby Version

**Current state:** Ruby 2.6.10 (Penn's internal team already advanced from 2.3).

**Decision:** Target Ruby 2.7 as the Phase 1 ceiling. Rails 4.2 tolerates 2.7 with
deprecation warnings but breaks on 3.0 due to keyword argument changes. Ruby 2.7 buys
more recent EOL coverage than 2.6 while remaining feasible with the current Rails and
Blacklight constraints.

---

### `thredded` (Forum)

**Current state:** `thredded 0.9.4` mounted at `/forum`. Forum is actively used by
Penn Libraries users. Integration is minimal — one concern file
(`app/models/concerns/thredded_null_user_permissions.rb`) and a single engine mount
in `config/routes.rb`.

**Decision:** Keep `thredded 0.9.4` pinned as-is for Phase 1. It is compatible with
Rails 4.2 and Devise. The primary risk is a transitive dependency conflict introduced
by Blacklight 6. If a conflict arises, the forum may be temporarily disabled to maintain
momentum on the primary goal. Any deferral decision requires client confirmation.

**High risk note:** The app replaces Thredded's entire Pundit-based permission system
with a custom null-object mixin injected into `Thredded::ApplicationController`. This
override is fragile — any Thredded upgrade must verify `authorize_reading` and
`authorize_creating` method names still match. See `docs/gem_override_audit.md`.

**Phase 2 note:** Full thredded upgrade (to 1.0+ or replacement) is a Phase 2 item.

---

### Failing Specs Baseline

**Current state:** 48 failing specs across 371 examples (72.39% line coverage).

**Categorized failures:**

| Group | Count | Description |
|---|---|---|
| Test environment / setup | 2 | `tools_spec` (`.env` path), intermittent Capybara timing |
| External API / no mocking | 2 | `viaf_spec` hitting real VIAF endpoints without auth |
| Real app bugs | ~44 | Feature specs requiring investigation |

**Decision:** Fix all 48 failures and establish a clean green baseline *before* any
Blacklight or gem upgrades. This ensures we can distinguish pre-existing bugs from
upgrade regressions.

Notable failure already investigated: `login_spec` "should disallow login" — the
`inactive_message` method returns the same message for new unreviewed accounts and
explicitly de-activated accounts. The spec correctly expects distinct messaging.

---

### Gem Upgrade Targets

| Gem | Current | Target | Notes |
|---|---|---|---|
| blacklight | 5.14.0 | 6.x | Primary Phase 1 goal |
| ruby | 2.6.10 | 2.7.x | Highest feasible with Rails 4.2 |
| mysql2 | unpinned | latest compatible | Assess during BL6 upgrade |
| devise | 4.7.1 | latest 4.x | Not far behind; assess compat |
| cancancan | 1.12.0 | 3.x | Major version jump, needs care |
| paper_trail | 4.0.0 | latest compatible with Rails 4.2 | Major jump |
| sunspot_rails | 2.2.0 | pinned | Do not upgrade in Phase 1 |
| thredded | 0.9.4 | pinned | Do not upgrade in Phase 1 |

---

### Solr Server Upgrade Path

Blacklight 6 dropped Jetty/Jettywrapper and expects a standalone Solr 7/8 server.
The `jettywrapper` gem and embedded Solr startup must be replaced with the standalone
`solr` Docker service already present in `docker-compose.yml`. The Solr Docker image
will need to be upgraded from 4.2.0 to 8.x. Schema and configuration migration will
be required.

---

## Sprint 1 Priorities (Mar 30 – Apr 10, 2026)

1. **Fix 48 failing specs** — establish a clean green baseline
2. **Blacklight 6 dependency conflict analysis** — run `bundle update blacklight --dry-run`
   to surface all conflicts before touching code
3. **Solr server version assessment** — confirm upgrade path from 4.2.0 → 8.x
4. **Ruby 2.7 feasibility check** — identify keyword argument deprecation warnings
   and assess scope of fixes needed

With two engineers in parallel, the suggested split is:
- Engineer 1: Failing specs baseline
- Engineer 2: Blacklight 6 dependency conflict analysis + Solr assessment

---

## Gem Override Audit

A full audit of every gem override, monkey-patch, and view shadow is in
`docs/gem_override_audit.md`. This should be the first reference when planning
any change that touches Blacklight, Devise, Sunspot, Thredded, or DelayedJob.

**High risk items identified:**
- 13 Blacklight overrides that have breaking changes in BL6 (see audit for details)
- Both `BlacklightAdvancedSearch` override points have breaking changes in BAS 6.x
- Thredded permission injection — fragile, method-name sensitive
- `delayed_job` — directly reopens `Delayed::Backend::ActiveRecord::Job.reserve` via
  `class << self` to suppress SQL logging; silently breaks if DJ renames the method

---

## Blacklight Override Inventory

See `docs/gem_override_audit.md` for the full breakdown by gem, including risk levels
and BL6 compatibility notes for each override point.

---

## Phase 2 Roadmap Items (out of Phase 1 scope)

- RSolr migration (Sunspot → RSolr)
- Blacklight 6 → 7 upgrade
- Rails 4.2 → 5.x upgrade
- Bootstrap 3 → 4 migration (265+ view templates — "view-by-view" impact assessment needed)
- `thredded` upgrade to 1.0+ or replacement
- Ruby 3.x assessment

AI Usage Disclosure: Reviewed, revised, and extended by Claude Sonnet 4.6 (Anthropic).
