# Rails 6.1.7.10 → 7.2.3.1 Upgrade Plan

Produced 2026-04-15. Research-only document — no code changes.

Previous upgrade plan (Rails 5.2 → 6.1) preserved in git history as
`docs/rails_6_upgrade_plan.md`.

**Starting point (tagged `upgrade-6-rails-6-1-blacklight-7-ruby-3-2`):**
Ruby 3.2.8 / Rails 6.1.7.10 / Blacklight 7.41.0 / BAS 7.0.0 /
Sunspot 2.7.1 / Bootstrap 4.6.2 / Zeitwerk autoloader enabled

---

## Strategy

Two-phase approach — decouple the Rails framework upgrade from asset pipeline
modernization:

1. **Step D — Rails 7.2.3.1** (keep Sprockets, CoffeeScript, existing JS stack)
2. **Step E — Asset pipeline modernization** (importmaps, Stimulus, Hotwire)

---

## Step D: Rails 6.1.7.10 → 7.2.3.1

### D1. Gem Changes

Only two gems **must** change:

| Gem | Current | Change to | Why |
|-----|---------|-----------|-----|
| `rails` | `~> 6.1.0` | `~> 7.2.0` | Target version |
| `devise` | `~> 4.7.1` | `~> 4.9` | 4.7.x breaks on Rails 7 (`undefined method 'reference'` in Zeitwerk) |

**Verified compatible as-is (no changes needed):**

| Gem | Constraint | Why it's fine |
|-----|-----------|---------------|
| `sprockets` | `~> 3.7` | `sprockets-rails 3.5.2` requires `sprockets >= 3.0.0`, no upper bound |
| `sprockets-rails` | (transitive) | Requires `actionpack >= 6.1`, no upper bound |
| `blacklight` | `>= 7.7, < 8` | 7.41.0 declares `rails >= 6.1, < 8.1` |
| `sunspot_rails` | `~> 2.7.0` | Requires `rails >= 5`, no upper bound |
| `activerecord-session_store` | `~> 2.0` | Requires `>= 6.1` |
| `delayed_job` | `~> 4.1.0` | Requires `activesupport < 9.0` |
| `coffee-rails` | `~> 5.0` | Requires `railties >= 5.2.0` |
| `web-console` | `~> 4.1` | Requires `railties >= 6.0.0` |
| `puma` | (unpinned) | No Rails constraint |
| `turbolinks` | `~> 5.2` | No Rails upper bound |

### D2. Bundle Update

```bash
docker compose exec app bash -c "bundle update rails devise"
```

Commit updated `Gemfile` and `Gemfile.lock` together.

### D3. Run `bin/rails app:update` (Selective)

```bash
docker compose exec app bash -c "bundle exec rails app:update"
```

Review each generated file — accept only boilerplate updates, skip anything
that overwrites our customizations. Key outputs:

- `config/environments/*.rb` — review new defaults, keep existing overrides
- `bin/*` — accept updates
- `new_framework_defaults_7_0.rb` (and 7_1, 7_2) — for incremental opt-in

### D4. Boot on Rails 7.2 with load_defaults "6.1"

**Do NOT jump to `config.load_defaults "7.2"`.** Keep `"6.1"` initially to
decouple the gem upgrade from behavioral changes.

```bash
docker compose exec app bash -c "bundle exec rails runner 'puts Rails.version'"
docker compose exec app bash -c "bundle exec rake sunspot:reindex"
```

### D5. Bump load_defaults Incrementally

Use the generated `new_framework_defaults_*` files to enable new defaults
one at a time, testing after each:

1. `config.load_defaults "7.0"` — test
2. `config.load_defaults "7.1"` — test
3. `config.load_defaults "7.2"` — test, then remove incremental files

Key behavioral changes to watch:

| Version | Change | Impact |
|---------|--------|--------|
| 7.0 | `verify_foreign_keys_for_fixtures` default true | May affect test fixtures |
| 7.0 | `cache_format_version = 7.0` | Cache format change |
| 7.0 | `default_headers` removes X-Download-Options | Low |
| 7.1 | `run_commit_callbacks_on_first_saved_instances_in_transaction = false` | May affect callbacks |
| 7.1 | `to_time_preserves_timezone = :zone` | May affect time handling |
| 7.2 | `automatically_invert_plural_associations = true` | May affect associations |

### D6. Devise 4.9 Changes

- Review `config/initializers/devise.rb` for deprecated config options
- Test all auth flows: login, logout, signup, password reset
- Check if Devise 4.9 needs new migrations

### D7. Execution Order

```
Step D: Rails 6.1 → 7.2.3.1
├── 1. Bump rails ~> 7.2.0, devise ~> 4.9 + bundle update
├── 2. Run bin/rails app:update (selective)
├── 3. Boot with load_defaults "6.1", fix any boot errors
├── 4. Run full spec suite, triage failures
├── 5. Commit: "Upgrade Rails 6.1 → 7.2.3.1"
├── 6. Bump config.load_defaults "7.0", test
├── 7. Bump config.load_defaults "7.1", test
├── 8. Bump config.load_defaults "7.2", test
└── 9. Stabilize
```

---

## Known Non-Blockers

Codebase scanned for deprecated Rails APIs — none found:

- No `update_attributes`, `before_filter`, `render :text`, `redirect_to :back`
- No `config.secrets` or `Rails.application.secrets`
- No `ActionDispatch::Http::ParameterFilter`
- One `ActiveRecord::Base.connection.execute` in `user.rb:90` — still works

---

## Risk Areas

| Area | Risk | Notes |
|------|------|-------|
| Devise 4.7 → 4.9 | **High** | Version jump touches auth internals |
| Psych 4.x YAML | Medium | `blacklight_yaml_fix.rb` should handle it; verify |
| delayed_job monkey-patch | Medium | `config/initializers/delayed_job.rb` reopens `reserve` via `alias_method` |
| CoffeeScript | Low | One file: `app/assets/javascripts/sparql.js.coffee` |
| Bunny boot connection | Low | `config/application.rb:46` connects at boot; verify RabbitMQ |

---

## Step E: Asset Pipeline Modernization (Future)

Deferred to a separate phase after Rails 7.2 is stable.

- Replace Sprockets with importmaps
- Replace Turbolinks with Turbo (Hotwire)
- Add Stimulus for JS behavior
- Migrate `sparql.js.coffee` to plain JS
- Remove CoffeeScript, Uglifier dependencies

---

## Spec Verification Protocol

Suite runs ~25 minutes. Known flaky specs (do not count as failures unless
they fail consistently across 2-3 re-runs):

- `spec/features/manage_entries_spec.rb:46`
- `spec/features/advanced_search_spec.rb:29`
- `spec/features/search_spec.rb:60, :47, :135, :69, :30`
- `spec/features/bookmarks_watch_spec.rb:72`
- `spec/features/date_search_spec.rb:74, :110`
- `spec/features/groups_spec.rb:101, :77`

**Triage process:** Run full suite → re-run failures → re-run remaining
failures → anything still failing is a real failure.

---

AI Usage Disclosure: Researched and produced by Claude Opus 4.6 (Anthropic).
