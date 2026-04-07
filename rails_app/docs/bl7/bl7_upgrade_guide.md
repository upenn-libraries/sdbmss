# SDBM Blacklight 6 → 7 Upgrade Guide

**Date:** 2026-04-07
**Related epic:** [#56 — Blacklight 6→7 Upgrade Path Documentation](https://github.com/upenn-libraries/sdbmss/issues/56)
**Supporting docs:**
- `docs/gem_override_audit.md` — full inventory of every override to re-verify
- `docs/bootstrap_3_4_triage.md` — Bootstrap migration spike (280 templates)
- `docs/bootstrap_3_4_template_inventory.md` — per-file BS4 checklist
- `docs/roadmap_blacklight_7.md` — overall Phase 2 sequencing

---

## Version Targets

BL7 is upgraded in two steps aligned with the Rails upgrade path:

| Step | BL Version | Ruby | Rails | When |
|---|---|---|---|---|
| Sprint 1 | **6.25 → 7.33** | 2.7.8 (unchanged) | 5.2.8 (unchanged) | Phase 2 Sprint 1 |
| Sprint 3 | **7.33 → 7.41** | 2.7.8 or 3.x | 6.1 (concurrent) | Phase 2 Sprint 3 |

**Why 7.33 first:** BL 7.33 requires Ruby >= 2.5 and Rails >= 5.1, < 7.1 — fully compatible with the current stack. No Ruby or Rails upgrade needed as a prerequisite.

**Why 7.41 later:** BL 7.41 requires Rails >= 6.1. It cannot be installed until the Sprint 3 Rails upgrade. Bump BL to 7.41 in the same PR as the Rails 6.1 upgrade.

**Ruby 3:** Not required by any BL7 version. Required for BL8+. Can be upgraded independently at any point in the sequence.

---

## BL7 Architecture Changes

BL7 is a significant architectural departure from BL6. The key changes every app override must be evaluated against:

### ViewComponent

BL7 introduced `ViewComponent` for rendering document partials. The gem's default views are now component-based. The app shadows all 22 catalog views, so the impact is primarily:
- The app's shadow views must be re-diffed against BL7's new partial structure
- Slot-based partials replace some include-style rendering

### Tool configuration moved to controller

BL6 rendered tools (bookmark, email, SMS, citation, sort, per-page, view type) implicitly. BL7 requires explicit configuration in the `configure_blacklight` block. These must be added to `catalog_controller_configuration.rb`:

```ruby
config.add_results_document_tool(:bookmark, partial: 'bookmark_control', if: :render_bookmarks_control?)
config.add_results_collection_tool(:sort_widget)
config.add_results_collection_tool(:per_page_widget)
config.add_results_collection_tool(:view_type_group)
config.add_show_tools_partial(:bookmark, partial: 'bookmark_control', if: :render_bookmarks_control?)
config.add_show_tools_partial(:email, callback: :email_action, validator: :validate_email_params)
config.add_show_tools_partial(:sms, if: :render_sms_action?, callback: :sms_action, validator: :validate_sms_params)
config.add_show_tools_partial(:citation)
config.add_nav_action(:bookmark, partial: 'blacklight/nav/bookmark', if: :render_bookmarks_control?)
config.add_nav_action(:search_history, partial: 'blacklight/nav/search_history')
```

### `fetch_one` removed

`Blacklight::SearchHelper#fetch_one` was removed in BL7. The app overrides this method in `config/initializers/blacklight_advanced.rb` to prepend `"Entry "` to numeric IDs (Sunspot ID format). This override must be replaced before upgrading.

**Replacement approach:** Implement the same `"Entry "` prepend logic via `Blacklight::SearchService` or the repository layer. See `docs/gem_override_audit.md` row #4 for context. This is also the point to consider activating the `EntryAdapter` in `config/initializers/sunspot.rb` to fix the root cause rather than patch the symptom.

### Modal: `ajax_modal` → `modal`

The shared partial `shared/ajax_modal` was renamed to `shared/modal`. Any layout referencing the old name must be updated. The app's `app/views/layouts/` should be checked for this reference.

### `Blacklight::Utils` removed

`Blacklight::Utils` (a Rails 4 compatibility shim) was removed in BL7. The app's `user.rb` should be checked for the `needs_attr_accessible?` block and removed if present.

### Bootstrap 4

BL7's default views use Bootstrap 4 throughout. The app's 280 templates are migrated to BS4 in Sprint 2, immediately after BL7 is stable. See `docs/bootstrap_3_4_triage.md` for full scope. Font Awesome 5 is the chosen glyphicon replacement.

---

## App-Specific Override Re-verification

Every override in `docs/gem_override_audit.md` must be re-verified against BL7 source. The following are the highest-risk items:

### 1. `fetch_one` (BREAKING — must resolve before upgrade)

**File:** `config/initializers/blacklight_advanced.rb`
**Current:** Overrides `Blacklight::SearchHelper#fetch_one` to prepend `"Entry "` to IDs
**BL7 change:** `fetch_one` is removed from `SearchHelper`
**Required action:** Replace with equivalent logic in `Blacklight::SearchService`. Consider activating the commented-out `EntryAdapter` in `config/initializers/sunspot.rb` to fix the root cause at the same time.

### 2. `Catalog#facet` (verify)

**File:** `config/initializers/blacklight_advanced.rb`
**Current:** Overrides to add custom 404 branch; updated for BL 6.25 XHR format
**BL7 change:** Verify `facet` action signature and `get_facet_field_response` API unchanged
**Required action:** Re-diff against BL7 `Blacklight::Catalog`

### 3. `url_for_document` (verify)

**File:** `lib/sdbmss/blacklight.rb`
**Current:** Falls back to `entry_path(doc["entry_id"])` to strip `"Entry "` from Sunspot IDs
**BL7 change:** `url_for_document` interface changed in BL7
**Required action:** Re-verify method signature and behaviour in `Blacklight::UrlHelperBehavior`

### 4. `ShowPresenter` (verify)

**File:** `lib/sdbmss/blacklight.rb`
**Current:** `SDBMSS::Blacklight::ShowPresenter < Blacklight::ShowPresenter` — overrides `#heading`
**BL7 change:** `ShowPresenter` is now ViewComponent-based; verify inheritance and `#heading` override still applies
**Required action:** Re-diff against BL7 `Blacklight::ShowPresenter`

### 5. `SearchBuilder` (verify)

**File:** `app/models/search_builder.rb` + `lib/sdbmss/blacklight.rb`
**Current:** 10 custom processor methods; `default_processor_chain +=`
**BL7 change:** `SearchBuilder` processor chain API is stable across BL6/7 — low risk
**Required action:** Smoke test all 10 processors; confirm `default_processor_chain` still works

### 6. Catalog views — all 22 shadows (re-diff required)

All 22 files in `app/views/catalog/` must be re-diffed against BL7 gem source. The most impacted:

| File | Expected BL7 change |
|---|---|
| `_show_default.html.erb` | ViewComponent rendering replaces partial rendering |
| `_show_tools.html.erb` | Tool rendering now driven by `add_show_tools_partial` config |
| `_document.html.erb` | Document presenter API changes |
| `_facets.html.erb` | Slot-based partial structure |
| `index.html.erb` | Collection tool rendering changed |
| `show.html.erb` | ShowComponent wrapping |

### 7. `blacklight_advanced_search` (verify compatibility)

**Current version:** 6.4.1
**Required:** A BL7-compatible release of `blacklight_advanced_search`
**Risk:** High — check the gem's release page before starting the BL7 sprint. If no BL7-compatible release exists, this may need to be forked or replaced.

---

## Step-by-Step Upgrade Procedure (Sprint 1)

### Pre-upgrade checklist

- [ ] Full test suite passing on BL 6.25
- [ ] Confirm `blacklight_advanced_search` has a BL7-compatible release
- [ ] Review `app/views/catalog/` shadows — note any that use `ajax_modal`

### Step 1: Replace `fetch_one` override

Before touching the Gemfile, replace the `fetch_one` override in `config/initializers/blacklight_advanced.rb` with a BL7-compatible equivalent. Verify it works against BL 6.25 first so the change is isolated from the gem bump.

### Step 2: Bump Blacklight to 7.33

```ruby
# Gemfile
gem 'blacklight', '~> 7.33'
gem 'blacklight_advanced_search', '<BL7-compatible version>'
gem 'bootstrap', '~> 4.0'        # add
# remove: gem 'bootstrap-sass'   # remove after BS4 migration (Sprint 2)
```

Run `bundle update blacklight blacklight_advanced_search`.

### Step 3: Add tool configuration to catalog controller

Add the `config.add_results_document_tool` / `add_show_tools_partial` / `add_nav_action` lines listed above to `app/controllers/concerns/catalog_controller_configuration.rb`.

### Step 4: Update layout

In any app layout referencing `shared/ajax_modal`, change to `shared/modal`.

### Step 5: Remove `Blacklight::Utils` reference

Check `app/models/user.rb` for the `Blacklight::Utils.needs_attr_accessible?` block and remove it.

### Step 6: Re-diff all 22 catalog view shadows

Work through each file in `app/views/catalog/` against the BL7 gem source. Use the per-file notes in the override audit as a starting checklist.

### Step 7: Run the test suite

```bash
docker compose exec app bash -c "RAILS_ENV=test bundle exec rspec"
```

Fix failures iteratively. The most likely failure sources are the catalog view re-diff items and any `SearchHelper` method calls that changed signature.

---

## Bootstrap 4 Migration (Sprint 2)

Follows immediately after BL7 is merged and stable. Full detail in `docs/bootstrap_3_4_triage.md`. Summary:

- **280 templates** across 4 tiers
- **Font Awesome 5** chosen as glyphicon replacement — implement a Rails helper or CSS shim at the start of Sprint 2 before touching any templates
- **96 files** require no changes
- **34 drop-in files** — mechanical class renames only
- **32 structural files** — panel→card, form labels, nav patterns
- **118 custom component files** — glyphicons + navbar + Blacklight catalog overrides (done here, against BL7's final structure)

Full per-file checklist: `docs/bootstrap_3_4_template_inventory.md`

---

## BL 7.33 → 7.41 (Sprint 3, concurrent with Rails 6.1)

When Rails is upgraded to 6.1 in Sprint 3, bump BL to 7.41 in the same PR:

```ruby
gem 'blacklight', '~> 7.41'
```

BL 7.41 requires Rails >= 6.1 and Ruby >= 2.7 (already met). Re-run the test suite after bumping. The delta between 7.33 and 7.41 is smaller than the 6→7 jump — focus on any deprecation warnings introduced between the two versions.

---

## Reference

- [Blacklight 7.0.1 upgrade guide](https://github.com/projectblacklight/blacklight/wiki/Update-to-Blacklight-7.0.1)
- [Blacklight Bootstrap 3→4 migration guide](https://github.com/projectblacklight/blacklight/wiki/Bootstrap-3-to-4-Migration-Guide)
- [GeoBlacklight BL7 upgrade PR](https://github.com/geoblacklight/geoblacklight/pull/621) — practical real-world reference
- [ArcLight](https://github.com/sul-dlss/arclight) — BL7 + Bootstrap 4 reference implementation
- [Bootstrap 4 migration guide](https://getbootstrap.com/docs/4.0/migration/)

---

AI Usage Disclosure: Analysis and recommendations produced by Claude Sonnet 4.6 (Anthropic) from a review of the application codebase and Blacklight upstream documentation.
