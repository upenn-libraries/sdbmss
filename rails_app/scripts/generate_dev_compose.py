#!/usr/bin/env python3
"""
generate_dev_compose.py — Generate rails_app/docker-compose.dev.yml for local development.

Usage (run from the project root):
    python3 rails_app/scripts/generate_dev_compose.py \\
        ansible/roles/app/templates/docker-compose.yml.j2 \\
        ansible/roles/delayed_job/templates/docker-compose.yml.j2 \\
        ansible/roles/interface/templates/docker-compose.yml.j2 \\
        ansible/roles/rabbitmq/templates/docker-compose.yml.j2 \\
        ansible/roles/solr/templates/docker-compose.yml.j2 \\
        ansible/roles/jena/templates/docker-compose.yml.j2 \\
        ansible/roles/traefik/templates/docker-compose.yml.j2 \\
        ansible/roles/mysql/templates/docker-compose.yml.j2

What it does:
    Reads each Ansible role's docker-compose.yml.j2 Jinja2 template, renders it
    using variables from generate_dev_compose.yml, then merges all rendered
    service definitions into a single docker-compose.dev.yml suitable for
    local development with plain Docker Compose (not Docker Swarm).

    During processing the script:
      - Strips Swarm-only directives (swarmMode, TLS cert resolvers, HTTPS
        redirect routers, etc.)
      - Hoists deploy.labels to top-level labels so Traefik routing works
        without Swarm
      - Converts environment map entries to list form
      - Removes Docker secrets blocks (replaced by plain env vars)
      - Renames *_FILE secret env vars to their plain equivalents

generate_dev_compose.yml:
    A YAML file of variable overrides supplied to the Jinja2 renderer.
    It sets local-development values that differ from production, including:
      - Image names/tags (may reference shell env vars via "${VAR}" syntax)
      - app_url: the local hostname Traefik routes to (e.g. sdbmss.localhost)
      - Replica counts (typically 1 for all services)
      - Traefik configuration (dashboard port, log level, etc.)
    Edit this file to change which images are used or to adjust local
    service configuration without touching the Ansible role templates.
"""
import os
import re
import sys
import yaml
from jinja2 import Environment


def preprocess(source):
    # Strip #jinja2: directive so yaml.safe_load doesn't choke
    source = re.sub(r"^#jinja2:.*\n", "", source)
    source = remove_secrets(source)
    source = simplify_environment(source)
    source = apply_patches(source)
    return source


def simplify_env_line(line):
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


def apply_patches(source):
    for old, new in ENV_VAR_RENAMES.items():
        source = source.replace(old, new)
    for old, new in PATH_RENAMES.items():
        source = source.replace(old, new)
    lines = [l for l in source.splitlines(keepends=True)
             if not any(s in l for s in LINES_TO_STRIP)]
    return "".join(lines)


def render_template(template_path, env_vars):
    with open(template_path) as f:
        source = f.read()

    source = preprocess(source)

    env = Environment()
    template = env.from_string(source)
    rendered = template.render(env_vars)

    return yaml.safe_load(rendered)


def hoist_deploy_labels(svc_def):
    """Move deploy.labels to top-level labels for non-swarm Docker Compose."""
    deploy = svc_def.get("deploy", {})
    deploy_labels = deploy.pop("labels", None)
    if deploy_labels:
        svc_def.setdefault("labels", [])
        svc_def["labels"] = deploy_labels + svc_def["labels"]
    return svc_def


def merge_compose(docs):
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
    """Custom dumper that renders None values as empty (no 'null')."""
    pass

ComposeDumper.add_representer(
    type(None),
    lambda dumper, data: dumper.represent_scalar("tag:yaml.org,2002:null", ""),
)

script_dir = os.path.dirname(os.path.abspath(__file__))
with open(os.path.join(script_dir, "generate_dev_compose.yml")) as f:
    env_vars = yaml.safe_load(f)

env_vars["is_development"] = True

output_path = os.path.join(script_dir, "../docker-compose.dev.yml")

template_paths = sys.argv[1:]
docs = [render_template(path, env_vars) for path in template_paths]
merged = merge_compose(docs)
output = yaml.dump(merged, Dumper=ComposeDumper, default_flow_style=False, sort_keys=False)

with open(output_path, "w") as f:
    f.write(output)

print(f"Written to {output_path}")
