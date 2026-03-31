# Gem Override Audit

Produced 2026-03-29 as pre-upgrade research. Documents every place the app overrides,
monkey-patches, or shadows behavior from an installed gem. Use this when planning the
Blacklight 5→6 upgrade and any companion gem bumps.

**Gem versions audited (from inside the app container):**

| Gem | Version |
|---|---|
| blacklight | 5.14.0 |
| blacklight_advanced_search | 5.1.4 |
| devise | 4.7.3 |
| devise-guests | 0.3.3 |
| cancancan | 1.12.0 |
| paper_trail | 4.0.2 |
| sunspot / sunspot_rails | 2.2.0 |
| delayed_job_active_record | 4.1.11 |
| thredded | 0.9.4 |
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

## Blacklight 5.14.0

| File | Gem Class / Method Overridden | What the Customization Does | Risk | BL6 Notes |
|---|---|---|---|---|
| `config/initializers/blacklight_advanced.rb` | `Blacklight::Catalog#facet` (gem line 81) | Rewrites the facet action to handle missing facets gracefully with a custom 404 branch; passes `order` to paginator | **High** | Method still exists in BL6 at same location; paginator API changed |
| `config/initializers/blacklight_advanced.rb` | `Blacklight::Solr::FacetPaginator#initialize` (gem line 40) | Adds `@order` attribute (`asc`/`desc`); reverses `all_facet_values` array when order is `asc` | **High** | `FacetPaginator` still in BL6 but constructor args changed; `mattr_accessor` approach for `request_keys` changed |
| `config/initializers/blacklight_advanced.rb` | `Blacklight::Facet#facet_paginator` (gem line 6) | Passes new `order:` keyword arg to `FacetPaginator.new` alongside existing `sort:`, `offset:`, `limit:` | **High** | In BL6, `Blacklight::Facet` was removed; paginator construction moved into `SearchService` |
| `config/initializers/blacklight_advanced.rb` | `Blacklight::SearchHelper#fetch_one` (gem line 286, private) | Prepends `"Entry "` to the numeric id before calling `repository.find`, mapping Blacklight's integer IDs to Sunspot's `"Entry N"` string format | **High** | In BL6, `fetch_one` was eliminated; `SearchHelper` became `SearchService`; `SolrRepository#find` is the correct new override point |
| `config/initializers/blacklight_advanced.rb` | `Blacklight::Solr::SearchBuilderBehavior#add_facet_paging_to_solr` (gem line 198) | Adds `facet.order` Solr parameter support alongside the existing `facet.sort` and `facet.page` params | **High** | Method still in BL6 `SearchBuilderBehavior` but `blacklight_params` accessor and `request_keys` handling changed |
| `config/initializers/blacklight_advanced.rb` | `Blacklight::SolrResponse::Facets::FacetField` — adds `#order` method | Exposes the `@options[:order]` value set from Solr params | Medium | `FacetField` class still in BL6 at same location |
| `config/initializers/blacklight_advanced.rb` | `Blacklight::SolrResponse::Facets` (private) `#facet_field_aggregations` | Rewrites the full facet aggregation builder to thread `facet.order` from Solr params into each `FacetField`'s options hash | **High** | `facet_field_aggregations` still exists in BL6 but internal structure of `FacetField` options changed |
| `lib/sdbmss/blacklight.rb` | `Blacklight::UrlHelperBehavior#url_for_document` (gem line 12) | Falls back to `entry_path(doc["entry_id"])` when the config-based route lookup fails, translating `SolrDocument` back to a numeric Entry URL | **High** | Method exists in BL6 but is now in `Blacklight::Engine` helpers; signature changed; `entry_id` field dependency must be verified |
| `lib/sdbmss/blacklight.rb` | `Blacklight::FacetsHelperBehavior` — adds `#render_facet_partials_home` (new method, not an override) | Splits facets into "before N" and "after N" groups for two-column layout rendering | Low | `FacetsHelperBehavior` still in BL6; additive method, low conflict risk |
| `lib/sdbmss/blacklight.rb` | `SDBMSS::Blacklight::SolrResponse < Blacklight::SolrResponse` | Custom subclass that adds an `objects_resultset` attribute for lazy-loading Entry AR objects from Solr results | **High** | `Blacklight::SolrResponse` was reorganized in BL6; subclassing requires updating the constructor and response parsing |
| `lib/sdbmss/blacklight.rb` | `SDBMSS::Blacklight::DocumentPresenter < Blacklight::DocumentPresenter` — overrides `#document_heading` (gem line 22) | Returns `model_object.public_id` instead of the configured title field | **High** | `Blacklight::DocumentPresenter` was split into `IndexPresenter` / `ShowPresenter` in BL6; `document_heading` no longer exists as a single method |
| `lib/sdbmss/blacklight.rb` | `SDBMSS::Blacklight::SearchBuilder < Blacklight::Solr::SearchBuilder` — 10 custom processor methods | Adds Solr `fq` filters for approval, deprecation, draft status, user ownership; translates app date-range param syntax into Solr range queries; handles facet prefix | Medium | `Blacklight::Solr::SearchBuilder` still in BL6; processor method pattern unchanged; `blacklight_params` accessor name unchanged |
| `app/controllers/catalog_controller.rb` | `Blacklight::Catalog` (include) — overrides `show`, `index`, `find_or_initialize_search_session_from_params`, `add_to_search_history`, `create_guest_user`, `facet_list_limit` | `show` adds manuscript linking and 404 handling; `index` adds CSV export; session methods gate-keep behind login and filter empty searches | **High** | `find_or_initialize_search_session_from_params` was renamed `search_session` in BL6; `add_to_search_history` removed |
| `app/controllers/entries_controller.rb` | `Blacklight::Catalog` + `BlacklightAdvancedSearch::Controller` (include) | Mounts the full BL search stack as a second endpoint for Entry search | **High** | Duplicate of all `catalog_controller.rb` migration concerns |
| `app/models/solr_document.rb` | `Blacklight::Solr::Document` (include) — overrides `#initialize` | Calls `objects_resultset.add(entry_id)` during construction to register the document in the lazy-load cache | **High** | BL6 `SolrDocument` initializer signature changed; `objects_resultset` is a custom global that must be threaded through differently |
| `app/models/search_builder.rb` | `Blacklight::SearchBuilder` (inherit) + `Blacklight::Solr::SearchBuilderBehavior` (include) | App's primary search builder; delegates config to `CatalogControllerConfiguration` concern | **High** | Primary BL6 migration target; class exists in BL6 but processor pipeline registration changed |
| `app/models/user.rb` | `Blacklight::User` (include) | Connects user to BL bookmarks/saved searches tables | Low | `Blacklight::User` still in BL6 at same location; stable |
| `app/helpers/application_helper.rb` | `Blacklight::BlacklightHelperBehavior#render_bookmarks_control?` and `#render_saved_searches?` | Returns `false` unless current user is signed in (BL default allows guests) | Low | Both methods still in BL6 `BlacklightHelperBehavior` |
| `app/views/catalog/` (22 files) | All Blacklight default catalog views | Full custom UI; BL6 partials are shadowed where listed below | Medium | **Audited vs Blacklight 6.9.0 (2026-03-31):** all overrides remain needed; `_facet_limit` uses `search_facet_path`; `_search_form` uses `search_state.params_for_search`; `_citation` keeps stock `document_heading(document)` (helper is not deprecated in BL6; only presenter `#document_heading` is); `_constraints` uses `btn-sm` on start-over link. See catalog table. |

### app/views/catalog/ (Blacklight 6.9.0 audit)

Compared to `blacklight` **6.9.0** (`app/views/catalog/` in the gem). **Shadows BL6 default** means the app supplies the same relative path as the gem; **App-only** means no BL6 catalog template at that path.

| File | vs BL6 | Purpose / notes |
|---|---|---|
| `_bookmark_control.html.erb` | Shadows | Custom bookmark UI (`model_object` + `bookmarks/*` partials); not BL guest bookmark forms |
| `_breadcrumbs.html.erb` | **App-only** | BL6 has no `catalog/_breadcrumbs`; app entry breadcrumbs (was mis-labeled as BL5 shadow in older audit) |
| `_constraints.html.erb` | Shadows | Start-over link forces `search_field=all_fields`; button class aligned with BL6 `btn-sm` |
| `_document.html.erb` | Shadows | Custom search result row from `document.model_object` |
| `_facet_limit.html.erb` | Shadows | No ajax-modal “more” link; `search_facet_path`; supports prefix `nil` for A–Z browsing |
| `_facet_pagination.html.erb` | Shadows (bugfix) | `content_tag :span` for disabled prev/next (avoids stray markup in BL6 default) |
| `_facets.html.erb` | Shadows | Selected-filters panel, `render_facet_partials_home`, show-more on home |
| `_home_text.html.erb` | Shadows | Full SDBM home / forum / survey (replaces BL welcome page) |
| `_results_pagination.html.erb` | Shadows | Pagination + CSV export for signed-in users |
| `_search_form.html.erb` | Shadows | `sdbmss_search_action_path`, advanced link, mobile layout; `search_state.params_for_search` for hidden fields |
| `_show_default.html.erb` | Shadows | Detail body via `entries/show` + `model_object` |
| `_show_header_default.html.erb` | Shadows | `public_id` + email/SMS/cite links (`Entry` Solr id format) |
| `_show_tools.html.erb` | Shadows | Toolbar `<li>`s only (no BL panel wrapper; fits app `show.html.erb` layout) |
| `_citation.html.erb` | Shadows | `model_object.to_citation`; title line matches BL6 stock (`document_heading`) |
| `_bookmark_all.html.erb` | App-only | Bulk bookmark / clear |
| `_save_current_search.html.erb` | App-only | JS “Save Search” button |
| `_save_search.html.erb` | App-only | Save search gated on `current_user` |
| `index.html.erb` | Shadows | Content-before-sidebar order; no sitelinks box |
| `show.html.erb` | Shadows | `content_for` breadcrumbs / add-entry / control-tools |
| `facet.html.erb` | Shadows | Full-page facet + constraints + custom A–Z prefix UI |
| `not_found.html.erb` | App-only | Catalog entry-not-found page |
| `legacy.html.erb` | App-only | Legacy URL landing |

---

## Blacklight Advanced Search 5.1.4

| File | Gem Class / Method Overridden | What the Customization Does | Risk | Upgrade Notes |
|---|---|---|---|---|
| `config/initializers/blacklight_advanced.rb` | `BlacklightAdvancedSearch::ParsingNestingParser#process_query` (gem line 4) | Adds support for array-valued fields (`author[]=Cicero&author[]=Sallust`) and custom boolean operators (`blank`, `not blank`, `less than`, `greater than`) | **High** | BAS 6.x for BL6 has a rewritten parser; `process_query` signature and internals changed significantly |
| `config/initializers/blacklight_advanced.rb` | `BlacklightAdvancedSearch::RenderConstraintsOverride#query_has_constraints?`, `#render_constraints_query`, `#render_search_to_s_q` (gem lines 6, 16, 95) | Overrides constraint rendering to suppress facet display in main search bar; adds `render_constraints_filters_side` for a separate facet display area; supports array-valued queries in constraint labels | **High** | BAS 6.x renamed `RenderConstraintsOverride`; all three overridden methods have different signatures |

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

## Thredded 0.9.4

| File | Gem Class / Method Overridden | What the Customization Does | Risk | Upgrade Notes |
|---|---|---|---|---|
| `config/initializers/thredded.rb` | `Thredded::AutoFollowAndNotifyJob#perform` (gem line 6) — reopened | Replaces email notification with in-app notification call | Medium | `perform` signature unchanged (`post_id`); notification internals are version-sensitive |
| `config/initializers/thredded.rb` | `Thredded::CreateMessageboard` (subclass) — overrides `#run`, suppresses `#first_topic_title` / `#first_post_content` | Disables auto-creation of first topic and post when a new messageboard is created | Medium | `run` still exists in gem; interactor pattern may change between 0.9.x versions |
| `config/initializers/thredded.rb` | `Thredded::ApplicationController` — injects `ThreddedNullUserPermissions` mixin | Replaces Thredded's Pundit-based permission system with a null-object that grants/denies based on app roles | **High** | `authorize_reading` and `authorize_creating` (gem lines 66, 72) are the actual override points; any Thredded upgrade must verify these method names |
| `app/views/thredded/` | Thredded built-in views (messageboards, posts, shared, users) | Custom-styled forum views | Low | Additive; stable unless Thredded changes locals passed to partials |

---

## invisible_captcha 1.1.0

| File | Gem Class / Method Overridden | What the Customization Does | Risk | Upgrade Notes |
|---|---|---|---|---|
| `app/controllers/registrations_controller.rb` | `invisible_captcha` (before_action) | Honeypot field on the registration form | Low | Gem usage only; no patches |

---

## Risk Summary

| Level | Items |
|---|---|
| **High** | BL5→6: `fetch_one`, `FacetPaginator`, `Blacklight::Facet`, `facet_field_aggregations`, `add_facet_paging_to_solr`, `DocumentPresenter`, `url_for_document`, `SolrResponse` subclass, `catalog_controller` session methods, `SolrDocument#initialize`, `SearchBuilder` base class · BAS `ParsingNestingParser` + `RenderConstraintsOverride` · Thredded permission injection |
| **Medium** | Devise `FailureApp` + `find_for_database_authentication` · Delayed Job `reserve` patch · Thredded `AutoFollowAndNotifyJob` + `CreateMessageboard` · Sunspot `searchable` blocks |
| **Low** | CanCanCan · PaperTrail · Devise controller/view overrides · Blacklight helper overrides · `Blacklight::User` include · Thredded views · invisible_captcha |

AI Usage Disclosure: Reviewed, revised, and extended by Claude Sonnet 4.6 (Anthropic).
