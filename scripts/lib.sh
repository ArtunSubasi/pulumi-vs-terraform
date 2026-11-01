# Shared helpers for prep.sh / reset.sh / check.sh. Source it, don't run it.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CACHE_DIR="$REPO_ROOT/.cache"
# One mirror for both tools: its layout is <registry host>/<namespace>/<type>/, so
# registry.terraform.io (Terraform) and registry.opentofu.org (OpenTofu) live side by side.
PROVIDER_MIRROR="$CACHE_DIR/provider-mirror"
CLI_CONFIG="$CACHE_DIR/cli.tfrc"

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m ok\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m !!\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mERR\033[0m %s\n' "$*" >&2; exit 1; }

rel() { echo "${1#"$REPO_ROOT"/}"; }

# Showcase dirs (NN-topic), optionally filtered by ONLY="02 04".
showcases() {
  local d n
  for d in "$REPO_ROOT"/[0-9][0-9]-*/; do
    d="${d%/}"; n="$(basename "$d")"
    if [ -n "${ONLY:-}" ]; then
      [[ " $ONLY " == *" ${n%%-*} "* ]] || continue
    fi
    echo "$d"
  done
}

# Terraform root modules: <showcase>/terraform/{final,live}
tf_projects() {
  local s v
  for s in $(showcases); do
    for v in ${VARIANTS:-final live}; do
      [ -d "$s/terraform/$v" ] && echo "$s/terraform/$v"
    done
    # Directory-per-environment roots (05): <showcase>/terraform/env-per-directory/<env>
    for v in "$s"/terraform/env-per-directory/*/; do
      v="${v%/}"
      [ "$(basename "$v")" = modules ] || [ ! -d "$v" ] || echo "$v"
    done
  done
}

# OpenTofu-only examples: <showcase>/opentofu/{final,live}
tofu_projects() {
  local s v
  for s in $(showcases); do
    for v in ${VARIANTS:-final live}; do
      [ -d "$s/opentofu/$v" ] && echo "$s/opentofu/$v"
    done
  done
}

# Pulumi projects: every Pulumi.yaml below <showcase>/pulumi/{final,live}
pulumi_projects() {
  local s v
  for s in $(showcases); do
    for v in ${VARIANTS:-final live}; do
      [ -d "$s/pulumi/$v" ] || continue
      find "$s/pulumi/$v" -name Pulumi.yaml -not -path '*/node_modules/*' -exec dirname {} \; | sort
    done
  done
}

# True if a directory declares providers (anything worth `init`-ing).
has_tf_code() { compgen -G "$1/*.tf" >/dev/null || compgen -G "$1/*.tofu" >/dev/null; }

# Use the offline provider mirror if prep.sh has built it (read by terraform and tofu).
use_mirror() {
  [ -f "$CLI_CONFIG" ] && export TF_CLI_CONFIG_FILE="$CLI_CONFIG"
  return 0
}
