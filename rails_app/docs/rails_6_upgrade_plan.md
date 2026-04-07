# Rails 5.2 → 6.1 Upgrade Plan

Produced 2026-04-06. Research-only document — no code changes.

This covers **Phase 3** from the upgrade roadmap: Rails 5.2 → 6.1 with
the corresponding gem upgrades (Blacklight 6.25 → 7.x, BAS 6.4 → 7.0,
PaperTrail 10.3 → 12.x, Sunspot 2.5 → 2.6+).

---

## Strategy: Two-Step Approach

Verified from `Gemfile.lock` — these gems have **hard `< 6` Rails constraints**
that block the Rails 6 upgrade:

| Gem | Constraint | Action |
|-----|-----------|--------|
| **blacklight 6.25.0** | `rails >= 4.2, < 6` | Must upgrade to BL 7.x first |
| **codemirror-rails 5.16.0** | `railties >= 3.0, < 6.0` | Must remove (vendor JS) |
| **blacklight_advanced_search 6.4.1** | `blacklight ~> 6.0` | Must upgrade to BAS 7.0 alongside BL 7.x |

These gems have **no Rails upper bound** and are not blockers:

| Gem | Constraint | Status |
|-----|-----------|--------|
| **sunspot_rails 2.5.0** | `rails >= 3` | No blocker |
| **sunspot 2.5.0** | (no Rails constraint) | No blocker |

Because of the hard `< 6` constraints, the upgrade must proceed in this order:

1. **Step A — Blacklight 7.x + Bootstrap 4** (staying on Rails 5.2).
   Upgrade BL, BAS, remove codemirror-rails, and do the BS3→BS4 migration.
   This removes the hard blockers.
2. **Step B — Rails 5.2 → 6.1** (direct, skipping 6.0). Use
   `config.autoloader = :classic` and `config.load_defaults "5.2"` initially.
   All `where.not` calls are single-key so the 6.1 NAND change is safe.

---

## Step A: Blacklight 7.x + BAS 7.0 + Bootstrap 4 (on Rails 5.2)

This is the larger and riskier of the two steps. It must be done first because
Blacklight 6.25 has a hard `rails < 6` constraint.

### A1. Target Versions

| Gem | Current | Target | Why |
|-----|---------|--------|-----|
| blacklight | 6.25.0 | **7.7.0 – 7.11.x** | First with Rails 6 support + Zeitwerk fixes; avoids `view_component` dep (added in 7.12+) |
| blacklight_advanced_search | 6.4.1 | **7.0.0** | Only BAS version for BL7; BAS 8.0 deletes `RenderConstraintsOverride` — defer |
| bootstrap-sass | 3.4.1 | **Remove** → bootstrap ~> 4.x | BL7 requires Bootstrap 4 |

### A2. Remove codemirror-rails

`codemirror-rails 5.16.0` has `railties < 6.0`. The gem is unmaintained
(already flagged as dead in the roadmap). Vendor the CodeMirror JS/CSS files
directly into `vendor/assets/` and remove the gem from the Gemfile.

### A3. SearchHelper → SearchService (HIGH)

The entire `Blacklight::SearchHelper` concern is replaced by
`Blacklight::SearchService`, a standalone PORO.

| BL6 (current) | BL7 |
|----------------|------|
| `search_results(params)` | `search_service.search_results` |
| `fetch(id)` | `search_service.fetch(id)` |
| `get_facet_field_response(...)` | `search_service.facet_field_response(...)` |

**SDBM impact — 2 patches must be updated:**

1. **`config/initializers/blacklight_advanced.rb` — `fetch_one` override:**
   Currently patches `Blacklight::SearchHelper`. Must target
   `Blacklight::SearchService` instead. BL7 provides `search_service_class`
   config, so a proper subclass is now possible instead of monkey-patching.

2. **`config/initializers/blacklight_advanced.rb` — `Catalog#facet` override:**
   Calls `get_facet_field_response` which becomes
   `search_service.facet_field_response`.

### A4. `search_field_def_for_key` Removed (HIGH)

BL7 removes this helper. 3 occurrences in `blacklight_advanced.rb` (lines
156, 199, 212) must change to `blacklight_config.search_fields[field]`.

### A5. View Partial Renames (MEDIUM)

The `_default` suffix is dropped:

| Current (BL6) | Required (BL7) |
|----------------|----------------|
| `_show_default.html.erb` | `_show.html.erb` |
| `_show_header_default.html.erb` | `_show_header.html.erb` |

Both files exist in `app/views/catalog/` and need renaming.

### A6. Other BL7 Changes (LOW risk)

- **`url_for_document`** — now delegates through `SearchState` rather than
  `UrlHelperBehavior`. The SDBM override in `lib/sdbmss/blacklight.rb` may
  need retargeting but the method signature is the same.
- **`Blacklight::Solr::Response`** — constructor options now take
  `:blacklight_config` instead of `:solr_document_model`. SDBM's custom
  `SolrResponse` subclass only adds `objects_resultset` and does not override
  the constructor — should be transparent.
- **SearchBuilder** — processor chain pattern unchanged. The 10 custom
  processor methods in `SDBMSS::Blacklight::SearchBuilder` should work.
- **ShowPresenter** — `#heading` override is stable in BL7.
- **Session methods** — `find_or_initialize_search_session_from_params` and
  `add_to_search_history` remain unchanged in BL7's `SearchContext`.

### A7. Blacklight Advanced Search 6.4.1 → 7.0.0

Minimal code changes — BAS 7.0.0 is almost identical to 6.4.1:

1. **`search_field_def_for_key`** → `blacklight_config.search_fields[field]`
   (3 occurrences in `blacklight_advanced.rb`, same fix as A4)
2. **`search_results(params)`** → `search_service.search_results` in the
   AdvancedController (if SDBM overrides it)
3. **View updates** — part of the BS4 migration (A8)

**What stays the same:**
- `ParsingNestingParser#process_query` — signature and logic unchanged.
  SDBM's complete override (array queries, custom operators) will work.
- Query parameter format (`field[]=value`, `op=AND|OR`) — unchanged.
- `RenderConstraintsOverride` — still present in BAS 7.0 (deleted in 8.0).
  SDBM's override works after the `search_field_def_for_key` fix.

**Warning:** BAS 8.0.0 deletes `RenderConstraintsOverride` entirely and
switches to a `clause`-based parameter format. That is a much larger change
and should be deferred.

### A8. Bootstrap 3 → 4 Migration (Largest Frontend Work)

**This is the single largest piece of work in the entire upgrade.**

#### Scale

| Item | Count |
|------|-------|
| Glyphicon references | **446 occurrences across 126 files** |
| Bootstrap 3 panel classes | **245 occurrences across 39 files** |

#### Key Changes Required

| Bootstrap 3 | Bootstrap 4 |
|-------------|-------------|
| `glyphicon glyphicon-*` | FontAwesome icons or SVG |
| `panel` / `panel-heading` / `panel-body` | `card` / `card-header` / `card-body` |
| `panel-default` | `card` |
| `well` | `card card-body bg-light` |
| `btn-default` | `btn-secondary` |
| `pull-left` / `pull-right` | `float-left` / `float-right` |
| `col-xs-*` | `col-*` |
| `push` / `pull` grid | `order-*` |
| `hidden-xs` / `visible-*` | `d-none d-sm-block` etc. |

#### Recommendation

This should be tackled as a dedicated sub-project with its own branch. Options:

1. **Incremental:** Update markup file-by-file alongside the BL7 upgrade
2. **Big-bang:** Do a single BS3→BS4 pass across all views before or after BL7
3. **Compatibility shim:** Use a BS3→BS4 compatibility layer temporarily

Option 2 is cleanest. The Blacklight 7 gem ships with BS4-compatible views,
so only the app's custom views need updating.

### A9. Step A Execution Order

```
Step A: Blacklight 7.x + BAS 7.0 + Bootstrap 4 (on Rails 5.2)
├── 1. Remove codemirror-rails, vendor JS/CSS
├── 2. Bootstrap 3 → 4 migration (446 glyphicon + 245 panel refs)
├── 3. Bump blacklight to ~> 7.7
├── 4. Bump blacklight_advanced_search to ~> 7.0
├── 5. Update SearchHelper → SearchService patches
├── 6. Update search_field_def_for_key → blacklight_config.search_fields
├── 7. Rename _show_default → _show, _show_header_default → _show_header
├── 8. Run full test suite, fix failures
└── 9. Stabilize
```

---

## Step B: Rails 5.2 → 6.1 (Direct)

With the BL7 and codemirror-rails blockers removed in Step A, the Rails
upgrade can proceed directly to 6.1. All `where.not` calls are single-key,
`force_ssl` is already commented out, and `update_attributes` only has 3
occurrences — the 6.0-to-6.1 breaking changes are trivial for this codebase,
so there is no reason to stabilize on 6.0 first.

### B1. Rails Framework Changes

#### Zeitwerk Autoloader

Rails 6.0 introduces Zeitwerk as the default autoloader. **We can opt out** by
setting `config.autoloader = :classic` in `config/application.rb`. Classic
autoloader is deprecated in 6.1 and removed in 7.0.

**Good news:** Zero `require_dependency` calls in the codebase and zero
`Module#parent` usage — two of the most common Zeitwerk blockers are absent.

**Zeitwerk migration (deferred to later):**
- File names must match constant names via `camelize`
- One top-level constant per file
- Run `bin/rails zeitwerk:check` to verify
- Sunspot `reindex` rake task needs a workaround (models not eager-loaded
  under Zeitwerk — GitHub issue sunspot/sunspot#964)

#### Host Authorization Middleware

New `HostAuthorization` middleware validates the `Host` header. Must configure
`config.hosts` for each environment or the app returns 403.

```ruby
# config/environments/development.rb
config.hosts << "app.sdbmss.orb.local"
config.hosts << "sdbmss.localhost"

# config/environments/production.rb
config.hosts << "sdbm.library.upenn.edu"  # adjust to actual value if in ENV variable or whatever
```

#### `update_attributes` → `update` (3 occurrences)

Removed in Rails 6.1. Must fix:

| File | Line | Change |
|------|------|--------|
| `app/controllers/entry_manuscripts_controller.rb` | 36 | `update_attributes!` → `update!` |
| `app/controllers/names_controller.rb` | 74 | `update_attributes` → `update` |
| `app/controllers/sources_controller.rb` | 225 | `update_attributes` → `update` |

#### `where.not` NAND Behavior Change (Rails 6.1)

Rails 6.1 changes `where.not` from NOR to NAND semantics when given multiple
conditions in a single hash. **14 occurrences across 7 files** audited:

**Assessment:** All 14 occurrences use single-key hashes, so the NAND/NOR
change has **no behavioral impact**. No action needed.

#### `force_ssl` (already clean)

Both `config/environments/production.rb` and `staging.rb` have `force_ssl`
already commented out. No action needed.

#### Cookie Metadata

`config.load_defaults "6.0"` enables `use_cookies_with_metadata = true`, which
makes cookies incompatible with pre-6.0 Rails. Since we are not running mixed
Rails versions, this is fine — but note that all existing sessions will be
invalidated on deploy.

#### `config.load_defaults` Strategy

| Step | Setting | Why |
|------|---------|-----|
| Initial 6.1 deploy | `"5.2"` | Decouple gem upgrade from behavioral changes |
| After 6.1 is stable | `"6.0"` | Enable 6.0 defaults (cookie metadata, mailer job) |
| When confident | `"6.1"` | Enable SameSite cookies, SSL 308 redirects |

### B2. Companion Gem Upgrades

#### Sunspot 2.5.0 → 2.6.0

| Item | Detail |
|------|--------|
| Why 2.6 | Solr 8 support (aligns with Solr 9 roadmap), bug fixes |
| Rails constraint | `rails >= 3` — **no blocker** (verified in Gemfile.lock) |
| Breaking changes | XML update format becomes default (was JSON) |
| Zeitwerk issue | `sunspot:reindex` needs workaround — models not eager-loaded |
| SDBM impact | Low — `searchable` DSL unchanged; field types unchanged |

#### B2a. Thredded Removal Checklist

Client confirmed (2026-04-07) the forum is no longer needed. Remove entirely
instead of upgrading. Migrations stay (they're history); add a new migration
to drop the tables.

**Gem & config:**

- [ ] Remove `gem 'thredded'` from `Gemfile` (line 115)
- [ ] Delete `config/initializers/thredded.rb`
- [ ] Remove `mount Thredded::Engine => '/forum'` from `config/routes.rb` (line 3)

**Model/concern:**

- [ ] Delete `app/models/concerns/thredded_null_user_permissions.rb`

**Views — delete:**

- [ ] Delete entire `app/views/thredded/` directory (nav, users/link, messageboards/index, messageboards/form, posts/edit)

**Views — edit (remove Thredded references):**

- [ ] `app/views/shared/_search_navbar.html.erb` — remove "Community Forum" link (line 19)
- [ ] `app/views/catalog/_home_text.html.erb` — remove recent forum posts section (lines 66-89) and `.thredded--post--content` CSS (lines 15-16)
- [ ] `app/views/dashboard/_header.html.erb` — remove unread-posts badge + forum nav link (lines 80-82)
- [ ] `app/views/feedback/index.html.erb` — remove "post in forum" link (line 8)
- [ ] `app/views/dericci_games/splash.html.erb` — remove "suggest via community forum" link (line 173)

**Assets:**

- [ ] Remove `@import "thredded"` from `app/assets/stylesheets/application.scss` (line 23)
- [ ] Remove `.thredded--*` CSS rules from `app/assets/stylesheets/sdbmss.css.erb` (lines 52-80)
- [ ] Remove `//= require thredded` from `app/assets/javascripts/application.js` (line 15)

**Locales:**

- [ ] Remove `thredded:` section from `config/locales/en.yml` (line 24+)

**Database:**

- [ ] Add new migration to drop all `thredded_*` tables (~16 tables)
- [ ] Do NOT delete existing migrations (they're part of migration history)
- [ ] `db/schema.rb` updates automatically after migration runs

**Docs:**

- [ ] Update `docs/gem_override_audit.md` — remove Thredded entries (lines 23, 167-168)
- [ ] Update `docs/PHASE1-PLAN.md` — remove/update Thredded sections (lines 46-63, 100, 157)

#### PaperTrail 10.3 → 12.x

| Item | Detail |
|------|--------|
| Why 12 | Rails 6.1 support; 10.x only supports < 6.1 |
| Breaking changes | Engine → Railtie; `config.paper_trail` removed |
| SDBM impact | **Low** — no custom `PaperTrail::Version` subclass, no `config.paper_trail` usage |
| Upgrade path | Can skip 11.x and go straight to 12.3.0 |

#### Devise 4.7.1 — No Change Needed

Already compatible with Rails 6.x. Can optionally bump to 4.8.x for minor
fixes but not required.

#### delayed_job_active_record 4.1.x — Pin Verification

The `~> 4.1.0` Gemfile constraint should resolve to 4.1.7+, which supports
Rails 6.x (`activerecord >= 3.0, < 7.1`). Verify in `Gemfile.lock` after
bundle update.

#### Unicorn 4.9.0 — Keep For Now

Works with Rails 6.x. Switching to Puma introduces thread-safety risk that
is not worth taking during the upgrade. Revisit separately later.

### B3. Minor Gem Bumps

| Gem | Current | Target | Reason |
|-----|---------|--------|--------|
| `sass-rails` | ~> 5.0 | ~> 6.0 | Rails 6 compatibility |
| `coffee-rails` | ~> 4.2 | ~> 5.0 | Rails 6 compatibility |
| `web-console` | ~> 3.7 | ~> 4.1 | Rails 6 compatibility |
| `activerecord-session_store` | ~> 1.1 | ~> 2.0 | Rails 6 compatibility |
| `uglifier` | ~> 2.7.2 | ~> 4.2 | Drop old pin |
| `turbolinks` | ~> 5.2 | keep | Already compatible |
| `rspec-rails` | ~> 5.0 | ~> 5.0 or ~> 6.0 | Already compatible; 6.0 for Rails 6.1 |
| `capybara` | ~> 3.35 | ~> 3.35 | Already compatible |
| `factory_bot_rails` | ~> 5.2 | ~> 6.x | Optional bump |

### B4. Step B Execution Order

```
Step B: Rails 5.2 → 6.1 (direct)
├── 1. Fix update_attributes (3 files)
├── 2. Remove/replace codemirror-rails if not already done in Step A
├── 3. Add config.autoloader = :classic
├── 4. Add config.hosts entries per environment
├── 5. Bump rails to ~> 6.1
├── 6. Bump companion gems (sass-rails, coffee-rails, web-console, etc.)
├── 7. Bump PaperTrail to 12.x
├── 8. Remove Thredded gem (no longer needed)
├── 9. Bump Sunspot to 2.6.0 (optional — can defer to Solr 9 phase)
├── 10. Keep config.load_defaults "5.2"
├── 11. Run full test suite, fix failures
├── 12. Stabilize
├── 13. Bump config.load_defaults to "6.0", test, then "6.1", test
└── 14. Stabilize
```

---

## Risk Assessment

| Area | Risk | Effort | Notes |
|------|------|--------|-------|
| Bootstrap 3 → 4 | High | **Very High** | 446 + 245 occurrences across 126+ files |
| BL SearchHelper → SearchService | High | Medium | 2 monkey-patches to rewrite |
| BL view renames | Low | Low | 2 files |
| codemirror-rails removal | Low | Low | Vendor JS/CSS, remove gem |
| Rails 6.1 framework changes | Low | Low | All `where.not` single-key; `force_ssl` already clean |
| PaperTrail 12 | Low | Low | Clean codebase, no custom classes |
| Thredded removal | Low | Medium | 24 files; see B2a checklist |
| Sunspot 2.6 | Medium | Low | Zeitwerk reindex workaround needed |
| `update_attributes` removal | Low | Low | 3 simple renames |

**Overall assessment:** The Bootstrap 3 → 4 migration is the dominant work
item, accounting for roughly 60-70% of the total effort. The Rails framework
upgrade itself is relatively clean thanks to the single-key `where.not` pattern
and absence of other common blockers (`require_dependency`, `Module#parent`,
custom PaperTrail versions).

---

## Step C: Ruby 2.7.8 → 3.0 (After Rails 6.1 is Stable)

Ruby 3.0 is only supported on Rails 6.1+. This step should only happen after
Step B is fully stabilized.

### Why Ruby 3.0

- Ruby 2.7 is EOL (end-of-life since 2023-03-31) — no security patches
- Ruby 3.0 brings performance improvements (fiber scheduler, Ractor)
- Required for future Rails 7.x upgrades (Rails 7.0 requires Ruby 2.7+,
  Rails 7.2 requires Ruby 3.1+)

### The Keyword Argument Break (CRITICAL)

Ruby 3.0 completed the keyword argument separation that Ruby 2.7 deprecated.
Code that passes a hash as the last argument to a method expecting keyword
args will raise `ArgumentError` in Ruby 3.0 instead of warning in 2.7.

**Preparation (do during Steps A and B):**
- Run the test suite with `RUBYOPT="-W:deprecated"` on Ruby 2.7 to surface
  all keyword deprecation warnings
- Fix warnings as they appear — they preview exactly what breaks in 3.0

### Gem Compatibility

| Gem | Ruby 3.0 OK? | Notes |
|-----|-------------|-------|
| rails 6.1 | Yes | First Rails with Ruby 3.0 support |
| blacklight 7.7–7.11 | Yes | `required_ruby_version >= 2.5` (no upper bound) |
| blacklight_advanced_search 7.0 | Yes | No Ruby constraint |
| sunspot_rails 2.5/2.6 | **No** | Keyword arg issues; need **2.7.0+** for Ruby 3 fixes |
| paper_trail 12.x | Yes | `required_ruby_version >= 2.5` |
| ~~thredded~~ | N/A | Removed — no longer needed |
| devise 4.7+ | Yes | Tested with Ruby 3.0 |
| delayed_job 4.1.x | Yes | No Ruby constraint issues |
| unicorn 4.9.0 | **Uncertain** | Not tested with Ruby 3.x; may need upgrade or switch to Puma |
| `psych ~> 3.1` | **No** | Ruby 3.1+ ships Psych 4.x; must loosen pin |
| `nokogiri < 1.16` | **Check** | Older versions have Ruby 3 compilation issues |
| `ffi < 1.17` | **Check** | May need loosening for Ruby 3 native builds |

### Other Ruby 3.0 Breaking Changes

- **Positional/keyword arg separation** — the big one (see above)
- **`$SAFE` and `$VERBOSE` globals** — `$SAFE` removed; `$VERBOSE` behavior changed
- **`Object#freeze`** — frozen string literals becoming more common
- **`Hash#each` consistently ordered** — unlikely to affect app code
- **`Symbol#to_proc` arity** — edge case; unlikely to affect app code

### Execution Order

```
Step C: Ruby 2.7.8 → 3.0 (after Rails 6.1 is stable)
├── 1. Run test suite with RUBYOPT="-W:deprecated" — catalog all warnings
├── 2. Fix keyword argument warnings across app code and initializers
├── 3. Bump sunspot_rails to 2.7.0+ (Ruby 3 keyword arg fixes)
├── 4. Loosen/remove psych, nokogiri, ffi pins as needed
├── 5. Evaluate unicorn 4.9 on Ruby 3; switch to Puma if needed
├── 6. Update Dockerfile to Ruby 3.0.x
├── 7. Run full test suite, fix failures
└── 8. Stabilize
```

---

AI Usage Disclosure: Researched and produced by Claude Opus 4.6 (Anthropic).
