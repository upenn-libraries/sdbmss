# Blacklight 5 → 6 Dependency Conflict Analysis

**Date:** 2026-03-30
**Current:** blacklight 5.14.0
**Target:** blacklight 6.9.0

> **Outcome (2026-04-07):** All items in this analysis were completed. The application was
> advanced to Blacklight **6.25.0** (beyond the initial 6.9.0 target). All four Gemfile
> changes were applied, all 11 app patches were resolved, and the upgrade was validated
> against the test suite. See `gem_override_audit.md` for the full post-upgrade override
> inventory.

## Method

Blacklight 6.9.0 runtime dependencies were fetched from the rubygems.org API and
cross-referenced against the current `Gemfile.lock` to identify conflicts and
required Gemfile changes.

## BL6.9.0 Runtime Dependencies

| Gem | BL6 requires | Current (locked) | Status |
|-----|-------------|-----------------|--------|
| rsolr | `>= 1.0.6, < 3` | 1.0.13 | OK |
| bootstrap-sass | `~> 3.2` | 3.3.7 | OK |
| kaminari | `~> 1.0` | 1.2.2 | OK |
| rails | `>= 4.2, < 6` | 4.2.11.3 | OK |
| twitter-typeahead-rails | `= 0.11.1.pre.corejavascript` | **not in Gemfile** | **ADD** |
| jquery-rails | `>= 3.1, < 5` | 4.2.1 | OK |

## Verdict

**No hard version conflicts** with the current gem stack. All currently-locked versions
satisfy BL6's constraints.

## Required Gemfile Changes

### 1. Bump blacklight pin
```ruby
gem "blacklight", "~> 6.9.0"   # was ~> 5.14.0
```

### 2. Bump blacklight_advanced_search pin
BAS must track the Blacklight major version. Latest BL6-compatible release is 6.4.1.
```ruby
gem "blacklight_advanced_search", "~> 6.4.1"   # was ~> 5.1.3
```

BAS 6 replaces the `parsing_nesting` gem with `parslet`. The app has a
`BlacklightAdvancedSearch::ParsingNestingParser` monkey-patch in
`config/initializers/blacklight_advanced.rb` that will break and must be rewritten
against the `parslet`-based BAS 6 API.

### 3. Add twitter-typeahead-rails (new hard BL6 dep)
```ruby
gem "twitter-typeahead-rails", "= 0.11.1.pre.corejavascript"
```

### 4. Pin rsolr to ~> 1.0 (protective)
BL6 accepts rsolr up to `< 3`, so Bundler could silently upgrade to 2.x, which
changed the `SolrResponse` parsing API. The app monkey-patches `SolrResponse` in
`lib/sdbmss/blacklight.rb`, so an unintended rsolr upgrade could introduce subtle
bugs. Pinning prevents this.
```ruby
gem "rsolr", "~> 1.0"
```

## App Patches That Must Be Rewritten (11 total)

These are the monkey-patches identified in `docs/gem_override_audit.md` that will
break with BL6. The Gemfile bump triggers `bundle install` failures or runtime
errors until each is addressed.

| File | Class/Method | BL6 breaking change |
|------|-------------|---------------------|
| `config/initializers/blacklight_advanced.rb` | `Blacklight::Catalog` | Module include API changed |
| `config/initializers/blacklight_advanced.rb` | `Blacklight::Solr::FacetPaginator` | Removed/renamed |
| `config/initializers/blacklight_advanced.rb` | `Blacklight::Facet` | API changed |
| `config/initializers/blacklight_advanced.rb` | `Blacklight::SearchHelper` | Moved to `SearchService` |
| `config/initializers/blacklight_advanced.rb` | `Blacklight::Solr::SearchBuilderBehavior` | Module reorganised |
| `config/initializers/blacklight_advanced.rb` | `Blacklight::SolrResponse::Facets` | Moved to rsolr |
| `config/initializers/blacklight_advanced.rb` | `BlacklightAdvancedSearch::ParsingNestingParser` | Replaced by parslet |
| `config/initializers/blacklight_advanced.rb` | `BlacklightAdvancedSearch::RenderConstraintsOverride` | View helper changed |
| `lib/sdbmss/blacklight.rb` | `Blacklight::UrlHelperBehavior` | Helper methods renamed |
| `lib/sdbmss/blacklight.rb` | `Blacklight::FacetsHelperBehavior` | Helper renamed |
| `lib/sdbmss/blacklight.rb` | `SDBMSS::Blacklight::DocumentPresenter` | `DocumentPresenter` API overhauled |

## Next Steps

1. Apply the 4 Gemfile changes above.
2. Run `bundle install` inside Docker and capture full output.
3. Work through each of the 11 app patches in dependency order (start with
   `DocumentPresenter` and `SearchBuilder`, which are foundational).
4. Run the spec suite after each patch to confirm no regressions.

AI Usage Disclosure: Reviewed, revised, and extended by Claude Sonnet 4.6 (Anthropic).
