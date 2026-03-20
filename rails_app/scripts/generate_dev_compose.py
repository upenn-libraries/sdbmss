#!/usr/bin/env python3
"""
generate_dev_compose.py — Generate rails_app/docker-compose.yml for local development.

Usage (run from anywhere):
    python3 rails_app/scripts/generate_dev_compose.py

What it does:
    Reads each Ansible role's docker-compose template (Jinja2 .j2 or plain YAML),
    renders it using variables from generate_dev_compose.yml, then merges all
    rendered service definitions into a single docker-compose.yml suitable
    for local development with plain Docker Compose (not Docker Swarm).

    During processing the script:
      - Strips Swarm-only directives (swarmMode, TLS cert resolvers, HTTPS
        redirect routers, etc.)
      - Hoists deploy.labels to top-level labels so Traefik routing works
        without Swarm
      - Converts environment map entries to list form
      - Removes Docker secrets blocks (replaced by plain env vars)
      - Renames *_FILE secret env vars to their plain equivalents

    Non-Jinja2 files (e.g. plain docker-compose.yml) are safe to include: they
    pass through the Jinja2 renderer unchanged and receive the same transforms.

generate_dev_compose.yml:
    A YAML file of variable overrides supplied to the Jinja2 renderer.
    It sets local-development values that differ from production, including:
      - Image names/tags (may reference shell env vars via "${VAR}" syntax)
      - app_url: the local hostname Traefik routes to (e.g. sdbmss.localhost)
      - Replica counts (typically 1 for all services)
      - Traefik configuration (dashboard port, log level, etc.)
    Edit this file to change which images are used or to adjust local
    service configuration without touching the Ansible role templates.

    service_patches:
    An optional section in generate_dev_compose.yml for adding or replacing
    top-level attributes on any service after the compose file is generated.
    Useful for dev-only attributes (e.g. `build`) that don't exist in the
    Ansible role templates. Each key under a service replaces the existing
    attribute of that name outright — no deep merge is performed.

        service_patches:
          app:
            build:
              context: .

    service_array_appends:
    An optional section in generate_dev_compose.yml for appending items to
    list-type service attributes after the compose file is generated. Unlike
    service_patches, this merges rather than replaces — existing items are
    preserved and new items are appended.

        service_array_appends:
          app:
            environment:
              - SOLR_TEST_URL

🤖 Generated with Claude (claude.ai)
AI Usage Disclosure: Designed and implemented by Claude (Anthropic).
"""
import os
import re
import yaml
from jinja2 import Environment

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

# Paths to docker-compose templates, relative to this script's directory.
TEMPLATE_PATHS = [
    "../../ansible/roles/app/templates/docker-compose.yml.j2",
    "../../ansible/roles/delayed_job/templates/docker-compose.yml.j2",
    "../../ansible/roles/interface/templates/docker-compose.yml.j2",
    "../../ansible/roles/jena/templates/docker-compose.yml.j2",
    "../../ansible/roles/mysql/templates/docker-compose.yml.j2",
    "../../ansible/roles/rabbitmq/templates/docker-compose.yml.j2",
    "../../ansible/roles/solr/templates/docker-compose.yml.j2",
    "../../ansible/roles/chrome/files/docker-compose.yml",
    "../../ansible/roles/traefik/templates/docker-compose.yml.j2",
]

def preprocess(source):
    """
    Do a bunch of cleaning before the file is run through the Jinja2 processor:

    - Remove the #jinja2 directive
    - Remove the secrets section
    - Simplify the `environment:` section (see simplify_env_line)
    - Apply a number of arbitrary edits (apply_patches)
    """
    # Strip #jinja2: directive so yaml.safe_load doesn't choke
    source = re.sub(r"^#jinja2:.*\n", "", source)
    source = remove_secrets(source)
    source = simplify_environment(source)
    source = apply_source_patches(source)
    return source


def simplify_env_line(line):
    """
    For lines in the `environment:` block. We're going to pull all env variables
    from `.env`, so remove all variable values coming from
    Ansible, and use an array list of variable names instead of the key/values.

    Variable literal values are retained and Jinja2 flow controls are kept.

    Thus:

       environment:
         SOME_VAR: {{ var_from_ansible }
         ANOTHER_VAR: "some value"
         {% if is_development == true %}
         THIRD_VAR: {{ third_var_from_ansible }
         {% endif %}

    Becomes:

       environment:
         - SOME_VAR
         - ANOTHER_VAR="some value"
         {% if is_development == true %}
         - THIRD_VAR
         {% endif %}

    """
    stripped = line.rstrip()

    # Blank lines — pass through
    if not stripped:
        return line

    # Jinja2 control flow — pass through
    if re.match(r"^\s*\{%", stripped):
        return line

    # Value is a Jinja2 variable — just use the key name
    if re.search(r':\s*"?\{\{.*\}\}"?\s*$', line):
        return re.sub(r"(\w+):.*", r"- \1", line).rstrip() + "\n"

    # Value is a literal — preserve it
    m = re.search(r':\s*"([^"]*)"\s*$', line)
    if m:
        return re.sub(r'(\w+):\s*"([^"]*)"', r"- \1=\2", line).rstrip() + "\n"

    # Fallback — just the key name
    return re.sub(r"(\w+):.*", r"- \1", line).rstrip() + "\n"


def simplify_environment(source):
    """
    Run through the file and reorganize the `environment:` section for the
    docker compose (non-Ansible) environment. See `simplify_env_line()` for
    details.
    """
    lines = source.splitlines(keepends=True)
    result = []
    in_environment = False
    env_indent = 0

    for line in lines:
        m = re.match(r"^(\s*)environment:\s*$", line)
        if m:
            in_environment = True
            env_indent = len(m.group(1))
            result.append(line)
        elif in_environment:
            # Exit environment block when we hit a non-blank line at same or lesser indentation
            if line.strip() and len(line) - len(line.lstrip()) <= env_indent:
                in_environment = False
                result.append(line)
            else:
                result.append(simplify_env_line(line))
        else:
            result.append(line)

    return "".join(result)


def remove_secrets(source):
    """
    In the docker compose environment dev we use plain variables instead of
     secrets. Strip the secrets section.
    """
    lines = source.splitlines(keepends=True)
    result = []
    in_secrets = False
    secrets_indent = 0

    for line in lines:
        m = re.match(r"^(\s*)secrets:\s*$", line)
        if m:
            in_secrets = True
            secrets_indent = len(m.group(1))
        elif in_secrets:
            # Exit secrets block when we hit a non-blank line at same or lesser indentation
            if line.strip() and len(line) - len(line.lstrip()) <= secrets_indent:
                in_secrets = False
                result.append(line)
        else:
            result.append(line)

    return "".join(result)


ENV_VAR_RENAMES = {
    "MYSQL_ROOT_PASSWORD_FILE": "MYSQL_ROOT_PASSWORD",
    "MYSQL_PASSWORD_FILE": "MYSQL_PASSWORD",
}

PATH_RENAMES = {
    "/sdbmss/ansible/roles/app/files/src/": ".",
}

LINES_TO_STRIP = [
    "swarmMode",
    "swarmModeRefreshSeconds",
    "providers.swarm.",
    "redirectscheme",
    "app_https",
    "tls.certresolver",
    "routers.app_secure",
    "services.app_secure",
]

def apply_source_patches(source):
    """
    Apply a number of replacements and skips.
    """
    for old, new in ENV_VAR_RENAMES.items():
        source = source.replace(old, new)
    for old, new in PATH_RENAMES.items():
        source = source.replace(old, new)
    lines = [l for l in source.splitlines(keepends=True)
             if not any(s in l for s in LINES_TO_STRIP)]
    return "".join(lines)


def render_template(template_path, env_vars):
    """
    Preprocess and run the template through the Jinja2 processor; return the
    parsed yaml.
    """
    with open(template_path) as f:
        source = f.read()

    source = preprocess(source)

    env = Environment()
    template = env.from_string(source)
    rendered = template.render(env_vars)

    return yaml.safe_load(rendered)


def hoist_deploy_labels(svc_def):
    """Move Traefik deploy.labels to top-level labels for non-swarm Docker Compose."""
    deploy = svc_def.get("deploy", {})
    deploy_labels = deploy.pop("labels", None)
    if deploy_labels:
        svc_def.setdefault("labels", [])
        svc_def["labels"] = deploy_labels + svc_def["labels"]
    return svc_def


def merge_compose(docs):
    """
    Combine the rendered templates. Merge service, networks and volumes.
    """
    merged = {"version": "3.8", "services": {}}
    networks = {}
    volumes = {}

    for doc in docs:
        if not doc:
            continue
        for svc_name, svc_def in doc.get("services", {}).items():
            merged["services"][svc_name] = hoist_deploy_labels(svc_def)
        for net_name in doc.get("networks", {}).keys():
            networks[net_name] = {"name": net_name}
        for vol_name, vol_def in (doc.get("volumes") or {}).items():
            volumes[vol_name] = vol_def

    if networks:
        merged["networks"] = networks
    if volumes:
        merged["volumes"] = volumes

    return merged


class ComposeDumper(yaml.Dumper):
    """
    Custom dumper that renders None values as empty (no 'null').

    tag:yaml.org,2002:null the URI for null. This renders "" when the YAML would
    normally output null; so:

        volumes:
          rdf_data:
          sdbm_data:
          rabbitmq_data:
          sdbm_solr:
          certificates:

    Instead of:

        volumes:
          rdf_data: null
          sdbm_data: null
          rabbitmq_data: null
          sdbm_solr: null
          certificates: null
    """
    pass

ComposeDumper.add_representer(
    type(None),
    lambda dumper, data: dumper.represent_scalar("tag:yaml.org,2002:null", ""),
)


def apply_service_patches(merged, patches):
    """
    Apply patches from the service_patches section of generate_dev_compose.yml.

    For each service in patches, replace (or add) the specified top-level
    attributes on the merged service definition. Existing attributes with the
    same key are removed before the new value is set — no deep merge is
    attempted.

    Example generate_dev_compose.yml entry:

        service_patches:
          app:
            build:
              context: .
    """
    for svc_name, attrs in patches.items():
        svc = merged["services"].get(svc_name)
        if svc is None:
            continue
        for key, value in attrs.items():
            svc.pop(key, None)
            svc[key] = value
    return merged


def apply_service_array_appends(merged, appends):
    """
    Append items to list-type service attributes from the service_array_appends
    section of generate_dev_compose.yml.

    For each service, each key must reference a list attribute on the service.
    Items are appended to the existing list. Missing attributes are created.

    Example generate_dev_compose.yml entry:

        service_array_appends:
          app:
            environment:
              - SOLR_TEST_URL

    @param merged [dict] The merged compose structure.
    @param appends [dict] The service_array_appends mapping from the config file.
    @return [dict] The merged compose structure with appends applied.
    """
    for svc_name, attrs in appends.items():
        svc = merged["services"].get(svc_name)
        if svc is None:
            continue
        for key, items in attrs.items():
            existing = svc.setdefault(key, [])
            existing.extend(items)
    return merged


def load_config() -> dict:
    """Load and return the generate_dev_compose.yml config dict."""
    with open(os.path.join(SCRIPT_DIR, "generate_dev_compose.yml")) as f:
        config = yaml.safe_load(f)
    config["is_development"] = True
    return config


def render_templates(config: dict) -> list:
    """Render all Ansible role templates and return parsed YAML docs."""
    paths = [os.path.join(SCRIPT_DIR, p) for p in TEMPLATE_PATHS]
    return [render_template(path, config) for path in paths]


def apply_patches(merged: dict, config: dict) -> dict:
    """Apply service_patches and service_array_appends from config to merged compose."""
    service_patches = config.pop("service_patches", {}) or {}
    service_array_appends = config.pop("service_array_appends", {}) or {}
    if service_patches:
        merged = apply_service_patches(merged, service_patches)
    if service_array_appends:
        merged = apply_service_array_appends(merged, service_array_appends)
    return merged


def main():
    config = load_config()
    docs   = render_templates(config)
    merged = merge_compose(docs)
    merged = apply_patches(merged, config)

    output = yaml.dump(merged, Dumper=ComposeDumper, default_flow_style=False, sort_keys=False)
    output_path = os.path.join(SCRIPT_DIR, "../docker-compose.yml")
    with open(output_path, "w") as f:
        f.write(output)
    print(f"Written to {output_path}")


if __name__ == "__main__":
    main()
