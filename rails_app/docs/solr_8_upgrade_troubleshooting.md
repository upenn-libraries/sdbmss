# Solr 8 upgrade troubleshooting (SDBMSS)

## Scope (important)

This project has **two** Solr runtimes:

1. **Local dev only**: `rails_app/docker-compose.yml`.
2. **Staging/production**: deployed by Ansible via `ansible/roles/solr/templates/docker-compose.yml.j2`.

For staging/prod incidents, treat `rails_app/docker-compose.yml` as non-authoritative.

## Symptom

On Solr **8.1**, requests to a core path such as `/solr/development` may fail with:

- `NullPointerException`
- `org.apache.solr.servlet.SolrDispatchFilter.authenticateRequest(...)`

In SDBMSS this can surface as repeated redirects at the Rails layer because the
root route (`catalog#index`) always attempts a Solr query.

## Deployment-specific cause to check first

In Ansible environments, Solr is started from the **app image** with:

```yaml
command: ["bundle", "exec", "rake", "sunspot:solr:run"]
```

That means Solr server behavior is tied to the app image/gemset (including
`sunspot_solr`), not the local dev compose Solr image tag.

## Recommended fix (staging/prod)

1. Update Solr/runtime in the deployed app image path (Gemfile + image rebuild), then redeploy via Ansible.
2. Verify `security.json` behavior:
   - if auth is not intentionally enabled, ensure no stale auth config is loaded;
   - if auth is enabled, ensure required auth settings are complete and valid.
3. Confirm your reverse proxy is not injecting malformed auth headers to Solr.
4. Confirm your app points at a valid core URL, e.g. `http://solr:8983/solr/development`.

## Where to apply changes for staging/prod

- Solr service template: `ansible/roles/solr/templates/docker-compose.yml.j2`
- Staging Solr URL: `ansible/inventories/staging/group_vars/docker_swarm_manager/app.yml`
- Production Solr URL: `ansible/inventories/production/group_vars/docker_swarm_manager/app.yml`
- App image dependency lock: `rails_app/Gemfile`, `rails_app/Gemfile.lock`

## Verification commands

```bash
curl -sSf http://<solr-host>:8983/solr/admin/info/system | jq '.lucene.solr-spec-version'
curl -sSf http://<solr-host>:8983/solr/development/admin/ping
curl -sS "http://<solr-host>:8983/solr/development/select?q=*:*&rows=0"
```

If these commands succeed and Solr logs are clean, Rails redirect looping caused by
search unavailability should stop.
