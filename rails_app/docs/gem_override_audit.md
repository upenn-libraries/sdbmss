# Gem Override Audit

Produced 2026-03-29 as pre-upgrade research. Documents every place the app overrides,
monkey-patches, or shadows behavior from an installed gem. Use this when planning the
Blacklight 5→6 upgrade and any companion gem bumps.

**Last status update:** 2026-04-06 — BL 6.9→6.25 diff reviewed and breaking changes addressed.
`Catalog#facet` override updated for format.js removal; `_citation.html.erb` modal header added;
`fetch_many_document_params` configured. All rows re-verified against BL 6.25 source.

**Gem versions audited (from inside the app container):**

| Gem | Version |
|---|---|
| blacklight | 5.14.0 → 6.9.0 → **6.25.0** |
| blacklight_advanced_search | 5.1.4 → **6.4.1** |
| devise | 4.7.3 |
| devise-guests | 0.3.3 |
| cancancan | 1.12.0 |
| paper_trail | 4.0.2 |
| sunspot / sunspot_rails | 2.2.0 |
| delayed_job_active_record | 4.1.11 |

| invisible_captcha | 1.1.0 |

---

## Cross-Gem Root Cause: Sunspot `"Entry N"` ID Format

> **Read this first.** The single highest-risk cluster of patches all exist because
> Sunspot indexes records as `"Entry 1234"` strings while Blacklight expects numeric IDs.
> Fixing this integration point (a proper Sunspot adapter or switching to numeric IDs in
> the Solr schema) would allow removing patches 3–4 in the Blacklight table below.

Files involved:
1. `config/initializers/blacklight_advanced.rb` — `fetch_one` prepends `"Entry "` before `repository.find`
2. `lib/sdbmss/blacklight.rb` — `url_for_document` strips `"Entry "` back out to build the URL
3. `lib/sdbmss/blacklight.rb` — `SDBMSS::Blacklight::SearchBuilder` lives in the same custom builder that also works around this ID mismatch
4. `config/initializers/sunspot.rb` — the commented-out `EntryAdapter` was the intended proper fix and was never activated

---

## Blacklight 5.14.0 → 6.25.0

| # | File | Gem Class / Method Overridden | What the Customization Does | Risk | Status |
|---|---|---|---|---|---|
| 1 | `config/initializers/blacklight_advanced.rb` | `Blacklight::Catalog#facet` | Rewrites the facet action to handle missing facets gracefully with a custom 404 branch | **High** | **DONE (6.25)** — Updated in `efeaf02b` (BL5→6); updated again 2026-04-06 for BL 6.25: replaced `format.js { render layout: false }` with `format.html { return render layout: false if request.xhr? }` — BL 6.25 dropped the JS format entirely for Ajax modal requests. JSON 404 branch also trimmed (format.js removed). |
| 2 | `config/initializers/blacklight_advanced.rb` | `Blacklight::Solr::FacetPaginator#initialize` | Added `@order` attribute (`asc`/`desc`); reversed `all_facet_values` array when order is `asc` | **High** | **REMOVED** — deleted in `efeaf02b`; Solr never supported per-facet asc/desc; BL6 handles facet pagination internally |
| 3 | `config/initializers/blacklight_advanced.rb` | `Blacklight::Facet#facet_paginator` | Passed `order:` keyword arg to `FacetPaginator.new` | **High** | **REMOVED** — deleted in `efeaf02b`; `Blacklight::Facet` removed in BL6 |
| 4 | `config/initializers/blacklight_advanced.rb` | `Blacklight::SearchHelper#fetch_one` | Prepends `"Entry "` to numeric id before `repository.find` (Sunspot ID format) | **High** | **DONE (6.25)** — `fetch_one(id, extra_controller_params)` signature unchanged in BL 6.25 (`search_helper.rb:152`). Removal is planned for BL7, not BL6. Override still active and correct. |
| 5 | `config/initializers/blacklight_advanced.rb` | `Blacklight::Solr::SearchBuilderBehavior#add_facet_paging_to_solr` | Added `facet.order` Solr parameter support | **High** | **REMOVED** — deleted in `efeaf02b`; part of the non-functional facet ordering attempt |
| 6 | `config/initializers/blacklight_advanced.rb` | `Blacklight::SolrResponse::Facets::FacetField` — `#order` method | Exposed `@options[:order]` value from Solr params | Medium | **REMOVED** — deleted in `efeaf02b`; part of facet ordering |
| 7 | `config/initializers/blacklight_advanced.rb` | `Blacklight::SolrResponse::Facets#facet_field_aggregations` | Rewrote facet aggregation builder to thread `facet.order` | **High** | **REMOVED** — deleted in `efeaf02b`; part of facet ordering |
| 8 | `lib/sdbmss/blacklight.rb` | `Blacklight::UrlHelperBehavior#url_for_document` | Falls back to `entry_path(doc["entry_id"])` for Sunspot ID format | **High** | **DONE (6.25)** — `url_for_document` unchanged in BL 6.25 (`url_helper_behavior.rb`). Note: BL 6.25 changed `session_tracking_path` to pass the document object rather than `document.id`; the route helper calls `to_param` so the URL string is the same — no impact on this override. |
| 9 | `lib/sdbmss/blacklight.rb` | `Blacklight::FacetsHelperBehavior` — `#render_facet_partials_home` | Splits facets into "before/after N" groups for two-column layout | Low | **DONE (6.25)** — additive method; no conflict with BL 6.25. |
| 10 | `lib/sdbmss/blacklight.rb` | `SDBMSS::Blacklight::SolrResponse < Blacklight::Solr::Response` | Custom subclass adding `objects_resultset` for lazy-loading Entry AR objects | **High** | **DONE (6.25)** — `Blacklight::Solr::Response` constructor signature unchanged in BL 6.25. `GroupResponse#empty?` was added in 6.25 as an explicit method (previously fell through `method_missing`); this does not affect the custom subclass. |
| 11 | `lib/sdbmss/blacklight.rb` | `SDBMSS::Blacklight::ShowPresenter < Blacklight::ShowPresenter` — `#heading` | Returns `model_object.public_id` instead of configured title field | **High** | **DONE (6.25)** — BL 6.25 added a deprecation warning to `ShowPresenter#field_value` when called with a String (expects a `Configuration::Field` object); this override only touches `#heading` and does not call `field_value`, so no impact. `ShowPresenter` class itself is unchanged in 6.25. |
| 12 | `lib/sdbmss/blacklight.rb` | `SDBMSS::Blacklight::SearchBuilder` — 10 custom processor methods | Solr `fq` filters for approval, deprecation, draft, user ownership; date-range translation; facet prefix | Medium | **DONE (6.25)** — processor chain pattern stable across BL 6.x. `default_processor_chain +=` and `blacklight_params` accessor unchanged in BL 6.25. |
| 13 | `app/controllers/catalog_controller.rb` | `Blacklight::Catalog` — overrides `show`, `index`, `find_or_initialize_search_session_from_params`, `add_to_search_history`, `create_guest_user`, `facet_list_limit` | Session gating, CSV export, 404 handling, guest user | **High** | **DONE (6.25)** — `find_or_initialize_search_session_from_params` and `add_to_search_history` both present with the same signatures in BL 6.25 `search_context.rb`. New `agent_is_crawler?` method added in 6.25 short-circuits `find_search_session` for bots before `find_or_initialize_search_session_from_params` is reached; the app's `current_user` gate still applies. |
| 14 | `app/controllers/entries_controller.rb` | `Blacklight::Catalog` + `BlacklightAdvancedSearch::Controller` | BL search stack as second endpoint for Entry search | **High** | **DONE (6.25)** — includes `CatalogControllerConfiguration`; same methods as #13; no additional impact from 6.25 changes. |
| 15 | `app/models/solr_document.rb` | `Blacklight::Solr::Document` — overrides `#initialize` | Registers document in `objects_resultset` lazy-load cache | **High** | **DONE (6.25)** — `SolrDocument#initialize` signature unchanged in BL 6.25. BL 6.25 added `attribute` class method to `SolrDocument` (backport); no conflict with the app's `#initialize` override. |
| 16 | `app/models/search_builder.rb` | `Blacklight::SearchBuilder` + `SearchBuilderBehavior` | App's primary search builder; delegates to `CatalogControllerConfiguration` | **High** | **DONE (6.25)** — thin wrapper; `config.search_builder_class = SDBMSS::Blacklight::SearchBuilder` unchanged. |
| 17 | `app/models/user.rb` | `Blacklight::User` (include) | Connects user to BL bookmarks/saved searches tables | Low | **DONE (6.25)** — stable across BL versions. |
| 18 | `app/helpers/application_helper.rb` | `Blacklight::BlacklightHelperBehavior#render_bookmarks_control?` and `#render_saved_searches?` | Returns `false` unless signed in | Low | **DONE (6.25)** — both methods present and unchanged in BL 6.25 `BlacklightHelperBehavior`. |
| 19 | `app/controllers/concerns/catalog_controller_configuration.rb` | `Blacklight::Configuration` — `fetch_many_document_params` | Explicitly sets `{ fl: '*' }` | Low | **ADDED (6.25)** — BL 6.25 introduced a deprecation warning when `fetch_many_document_params` is not configured. Set to `{ fl: '*' }` to match the prior implicit default and silence the warning. |
| 20 | `app/views/catalog/` (22 files) | All Blacklight default catalog views | Full custom UI | Medium | **DONE (6.25)** — see view table below. |

### app/views/catalog/ (Blacklight 6.25.0 audit)

Compared to `blacklight` **6.25.0** (`app/views/catalog/` in the gem). **Shadows BL default** means the app supplies the same relative path as the gem; **App-only** means no BL catalog template at that path. Views not listed here are not present in either the app or the gem's catalog directory.

| File | vs BL | Purpose / notes | 6.25 delta |
|---|---|---|---|
| `_bookmark_control.html.erb` | Shadows | Custom bookmark UI (`model_object` + `bookmarks/*` partials); not BL guest bookmark forms | No gem change |
| `_breadcrumbs.html.erb` | **App-only** | BL6 has no `catalog/_breadcrumbs`; app entry breadcrumbs | No gem change |
| `_constraints.html.erb` | Shadows | Start-over link forces `search_field=all_fields`; button class aligned with BL6 `btn-sm` | No gem change |
| `_document.html.erb` | Shadows | Custom search result row from `document.model_object` | No gem change |
| `_facet_limit.html.erb` | Shadows | No ajax-modal "more" link; `search_facet_path`; supports prefix `nil` for A–Z browsing | No gem change |
| `_facet_pagination.html.erb` | Shadows | `content_tag :span` for disabled prev/next | BL 6.25 adopted the same `content_tag :span` fix the app already had — app version already correct |
| `_facets.html.erb` | Shadows | Selected-filters panel, `render_facet_partials_home`, show-more on home | No gem change |
| `_home_text.html.erb` | Shadows | Full SDBM home / forum / survey (replaces BL welcome page) | No gem change |
| `_results_pagination.html.erb` | Shadows | Pagination + CSV export for signed-in users | No gem change |
| `_search_form.html.erb` | Shadows | `sdbmss_search_action_path`, advanced link, mobile layout; `search_state.params_for_search` for hidden fields | BL 6.25 added `aria-label` to the form tag — not in app shadow, low risk |
| `_show_default.html.erb` | Shadows | Detail body via `entries/show` + `model_object`; does not call `field_value` | BL 6.25 changed `field_value field_name` → `field_value field` (object) in the gem's version; app shadow is unaffected since it doesn't call `field_value` at all |
| `_show_header_default.html.erb` | Shadows | `public_id` + email/SMS/cite links (`Entry` Solr id format) | No gem change |
| `_show_tools.html.erb` | Shadows | Toolbar `<li>`s only (no BL panel wrapper; fits app `show.html.erb` layout) | BL 6.25 added a `show_doc_actions?` guard around the panel; app shadow intentionally omits the panel wrapper — no action needed |
| `_citation.html.erb` | Shadows | `model_object.to_citation` with modal header | **Updated 2026-04-06** — BL 6.25 moved the modal header out of `citation.js.erb` and into `_citation.html.erb`; app doesn't shadow `citation.js.erb` so header must live here. Added `modal-header` div with close button (before `<h2>` per Bootstrap 3 float convention) and `modal-body` wrapper. |
| `_bookmark_all.html.erb` | App-only | Bulk bookmark / clear | No gem change |
| `_save_current_search.html.erb` | App-only | JS "Save Search" button | No gem change |
| `_save_search.html.erb` | App-only | Save search gated on `current_user` | No gem change |
| `index.html.erb` | Shadows | Content-before-sidebar order; no sitelinks box | No gem change |
| `show.html.erb` | Shadows | `content_for` breadcrumbs / add-entry / control-tools | No gem change |
| `facet.html.erb` | Shadows | Full-page facet + constraints + custom A–Z prefix UI | BL 6.25 updated close button to use `aria-label` + `aria-hidden span` (accessibility); app shadow retains old `aria-hidden="true"` button — minor a11y gap, not functional |
| `not_found.html.erb` | App-only | Catalog entry-not-found page | No gem change |
| `legacy.html.erb` | App-only | Legacy URL landing | No gem change |

---

## Blacklight Advanced Search 5.1.4 → 6.4.1

| # | File | Gem Class / Method Overridden | What the Customization Does | Risk | Status |
|---|---|---|---|---|---|
| 1 | `config/initializers/blacklight_advanced.rb` | `BlacklightAdvancedSearch::ParsingNestingParser#process_query` | Adds support for array-valued fields (`author[]=Cicero&author[]=Sallust`) and custom boolean operators (`blank`, `not blank`, `less than`, `greater than`) | **High** | **DONE** — verified 2026-03-31: multi-value OR, AND, and cross-field AND all return correct results. The override operates at the query-building layer which is unchanged between BAS 5.x and 6.x. Custom form JS (`_advanced_search_fields.html.erb`) generates `field[]=val` params correctly |
| 2 | `config/initializers/blacklight_advanced.rb` | `BlacklightAdvancedSearch::RenderConstraintsOverride#query_has_constraints?`, `#render_constraints_query`, `#render_search_to_s_q` | Overrides constraint rendering to suppress facet display in main search bar; adds `render_constraints_filters_side` for sidebar facets; supports array-valued queries in constraint labels | **High** | **DONE** — verified 2026-03-31: OR search shows "Any of:" prefix, each term displays with field label, remove links correctly preserve `op=OR` and remove only the clicked term |

---

## Devise 4.7.3

| File | Gem Class / Method Overridden | What the Customization Does | Risk | Upgrade Notes |
|---|---|---|---|---|
| `config/initializers/devise.rb` | `Devise::FailureApp` (subclass `CustomFailure`) — overrides `#redirect_url` (gem line 115) and `#respond` (gem line 37) | Provides app-specific redirect after auth failure; sets `authentication_keys: [:login]` to enable username-or-email login | Medium | Both methods stable in Devise 4.x; verify `redirect_url` still has no required args if upgrading |
| `app/controllers/registrations_controller.rb` | `Devise::RegistrationsController` (inherit) — overrides `#after_sign_up_path_for`, `#update_resource`, `#after_update_path_for` | Sends admin notification email on signup; handles password-optional updates; redirects to profile path | Low | Stable Devise override pattern unchanged since Devise 3.x |
| `app/controllers/application_controller.rb` | Devise mixin — `#configure_permitted_parameters`, `#after_sign_in_path_for` | Permits app-specific signup/update fields; redirects to dashboard after login | Low | `configure_permitted_parameters` contract unchanged |
| `app/models/user.rb` | `Devise::Models::DatabaseAuthenticatable#find_for_database_authentication` (gem line 235); `#active_for_authentication?`; `#inactive_message`; `#after_database_authentication` (gem line 172, default empty hook) | Allows login by username or email; gates login on `user.active` flag; logs auth event | Medium | `find_for_database_authentication` stable; `active_for_authentication?` hook stable |
| `app/views/devise/` (all subdirs) | All Devise built-in views | Fully custom-styled Devise views | Low | Additive; app views shadow gem views; no breakage unless Devise changes view locals |

---

## Devise-Guests 0.3.3

| File | Gem Class / Method Overridden | What the Customization Does | Risk | Upgrade Notes |
|---|---|---|---|---|
| `app/controllers/catalog_controller.rb` | `DeviseGuests::Controllers::Helpers#create_guest_user` | Adds `username:` field when creating guest user records (gem doesn't know about the app's `username` column) | Low | Isolated; method signature stable in 0.3.x |

---

## CanCanCan 1.12.0

| File | Gem Class / Method Overridden | What the Customization Does | Risk | Upgrade Notes |
|---|---|---|---|---|
| `app/models/ability.rb` | `CanCan::Ability` (include) | Defines all role-based permission rules for contributor / editor / super_editor / admin | Low | Standard pattern; stable across CanCanCan 1.x→3.x; verify `can :manage` syntax if jumping major versions |
| `app/controllers/application_controller.rb` | `rescue_from CanCan::AccessDenied` | Renders custom 403 | Low | `CanCan::AccessDenied` exception class unchanged across versions |

---

## PaperTrail 4.0.2

| File | Gem Class / Method Overridden | What the Customization Does | Risk | Upgrade Notes |
|---|---|---|---|---|
| `app/models/concerns/has_paper_trail.rb` | `has_paper_trail` call signature | Wraps `has_paper_trail` with a fixed `ignore:` field list to suppress audit noise | Low | PaperTrail 4→8: `ignore:` still accepts an array of symbols; verify field name format after upgrade |
| `app/models/user.rb`, `entry.rb`, `source.rb`, `comment.rb` | `HasPaperTrail` concern (include) | All auditable models delegate to the shared wrapper; single change point | Low | |

---

## Sunspot 2.2.0

| File | Gem Class / Method Overridden | What the Customization Does | Risk | Upgrade Notes |
|---|---|---|---|---|
| `app/models/entry.rb`, `source.rb`, `user.rb`, `comment.rb`, `manuscript.rb`, `language.rb`, `place.rb`, `name.rb` | `Sunspot::DSL` `searchable` blocks | Defines Solr index fields for each model; `entry.rb` conditionally disables `auto_index` via `ENV` var | Medium | Sunspot 2.2 DSL stable; field types (`text`, `string`, `integer`, `boolean`, `date`) unchanged; upgrading Solr schema may require field-type review |
| `config/initializers/sunspot.rb` | Custom `EntryAdapter` (fully commented out) | Was intended to override `index_id` to use `"Entry N"` format; never activated | Low | Dead code; no active risk |

---

## Delayed Job (delayed_job_active_record 4.1.11)

| File | Gem Class / Method Overridden | What the Customization Does | Risk | Upgrade Notes |
|---|---|---|---|---|
| `config/initializers/delayed_job.rb` | `Delayed::Backend::ActiveRecord::Job.reserve` (gem line 81) — reopened via `class << self` | Wraps the class method in `silence_active_record_logger` to suppress SQL logging during job polling | Medium | Directly reopens the class; if DJ renames `reserve` or changes its arity this silently breaks |

---

## invisible_captcha 1.1.0

| File | Gem Class / Method Overridden | What the Customization Does | Risk | Upgrade Notes |
|---|---|---|---|---|
| `app/controllers/registrations_controller.rb` | `invisible_captcha` (before_action) | Honeypot field on the registration form | Low | Gem usage only; no patches |

---

## Migration Status Summary (2026-04-06)

| Status | Count | Items |
|---|---|---|
| **DONE** | 18 | BL: `Catalog#facet` (updated for 6.25 XHR format change), `fetch_one`, `url_for_document`, `render_facet_partials_home`, `SolrResponse` subclass, `ShowPresenter#heading`, `SearchBuilder` (10 processors), `catalog_controller` overrides, `entries_controller`, `SolrDocument#initialize`, `search_builder.rb`, `Blacklight::User`, helper overrides, `fetch_many_document_params` config, catalog views (22 files) · BAS: `ParsingNestingParser`, `RenderConstraintsOverride` |
| **REMOVED** (intentional) | 5 | BL: `FacetPaginator#initialize`, `Blacklight::Facet#facet_paginator`, `add_facet_paging_to_solr`, `FacetField#order`, `facet_field_aggregations` — all part of non-functional facet asc/desc ordering; deleted in `efeaf02b` |
| **NEEDS REVIEW** | 0 | — |
| **NO CHANGE NEEDED** | 6 gems | Devise, Devise-Guests, Delayed Job, CanCanCan, PaperTrail, Sunspot, invisible_captcha — all overrides are independent of Blacklight; verified 2026-03-31 that none are affected by the BL5→6 migration. These gems have their own upgrade paths in Phase 2. |

### Known minor gaps (non-blocking)

- `facet.html.erb` close button: still uses old `aria-hidden="true"` style; BL 6.25 uses `aria-label` + `aria-hidden span`. Accessibility-only gap.
- `_search_form.html.erb`: missing the `aria-label` BL 6.25 added to the form tag. Accessibility-only gap.

### Audit corrections (historical)

Inaccuracies in the original BL5-era audit, corrected against running BL6 6.9.0 (2026-03-31):

- `fetch_one` was **not** eliminated in BL6 — it exists at `search_helper.rb:152` with the same signature (elimination happens in BL7)
- `find_or_initialize_search_session_from_params` was **not** renamed — it exists at `search_context.rb:66`
- `add_to_search_history` was **not** removed — it exists at `search_context.rb:79`
- `Blacklight::DocumentPresenter` was **not** split — it still exists at `document_presenter.rb:4`; `IndexPresenter` and `ShowPresenter` were added alongside it. The app uses `SDBMSS::Blacklight::ShowPresenter < Blacklight::ShowPresenter` (set via `config.show.document_presenter_class`).

AI Usage Disclosure: Reviewed, revised, and extended by Claude Sonnet 4.6 and Claude Opus 4.6 (Anthropic).
