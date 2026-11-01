#!/usr/bin/env bash
# Run every final/ project end to end: init → validate → apply → (tests) → destroy.
# Use it after `make prep` to prove the demo works before going on stage.
#
#   ONLY="02 05" scripts/check.sh     # just these showcases
#
# Requires a clean state (run `make reset` first). Leaves no state behind.
# Pulumi needs a passphrase: if PULUMI_CONFIG_PASSPHRASE is unset, a random one is
# generated for this run only (every stack it creates is removed again).
set -euo pipefail
source "$(dirname "$0")/lib.sh"
use_mirror
export PULUMI_SKIP_UPDATE_CHECK=true
export VARIANTS=final

# Secret inputs the check has to provide (typed by hand on stage, see the READMEs).
# Keys are showcase dirs, values are space-separated names. Values are random per run.
declare -A PULUMI_CHECK_SECRETS=(        # pulumi config set --secret <name>
  [06-secrets]="apiToken"
)
declare -A TF_CHECK_VARS=(               # TF_VAR_<name>, for Terraform and OpenTofu
  [06-secrets]="api_token state_passphrase"
)
random_secret() { echo "check-$(od -An -tx1 -N12 /dev/urandom | tr -d ' \n')"; }

if [ -z "${PULUMI_CONFIG_PASSPHRASE:-}" ]; then
  PULUMI_CONFIG_PASSPHRASE="check-$(od -An -tx1 -N16 /dev/urandom | tr -d ' \n')"
  export PULUMI_CONFIG_PASSPHRASE
fi

# Showcases that create real AWS resources. Skipped (not failed) without valid credentials.
AWS_SHOWCASES="03-state-refresh"
HAVE_AWS=0
aws sts get-caller-identity >/dev/null 2>&1 && HAVE_AWS=1

FAILED=()
SKIPPED=()
fail() { warn "$1"; FAILED+=("$1"); }

showcase_of() { local r; r="$(rel "$1")"; echo "${r%%/*}"; }

check_tf() {
  local p=$1 cmd=$2 f env v
  cd "$p"
  for v in ${TF_CHECK_VARS[$(showcase_of "$p")]:-}; do
    export "TF_VAR_$v=$(random_secret)"
  done
  if compgen -G "terraform.tfstate*" >/dev/null || [ -d terraform.tfstate.d ] || [ -d ../.state ]; then
    warn "$(rel "$p"): has state — run 'make reset' first"; return 1
  fi
  "$cmd" init -input=false -no-color >/dev/null
  "$cmd" validate -no-color >/dev/null
  if [ -d tests ]; then
    "$cmd" test -no-color >/dev/null
  fi
  if compgen -G "envs/*.tfvars" >/dev/null; then
    # One workspace per environment (showcase 05)
    for f in envs/*.tfvars; do
      env="$(basename "$f" .tfvars)"
      "$cmd" workspace new "$env" -no-color >/dev/null
      "$cmd" apply -input=false -auto-approve -no-color -var-file="$f" >/dev/null
      "$cmd" plan -input=false -detailed-exitcode -no-color -var-file="$f" >/dev/null
      "$cmd" destroy -input=false -auto-approve -no-color -var-file="$f" >/dev/null
      "$cmd" workspace select default -no-color >/dev/null
      "$cmd" workspace delete "$env" -no-color >/dev/null
    done
  else
    "$cmd" apply -input=false -auto-approve -no-color >/dev/null
    # A second plan must be empty, otherwise the config isn't idempotent.
    "$cmd" plan -input=false -detailed-exitcode -no-color >/dev/null
    "$cmd" destroy -input=false -auto-approve -no-color >/dev/null
  fi
  rm -rf out terraform.tfstate* terraform.tfstate.d
  # env-per-directory/prod keeps its state outside the root
  case "$p" in */env-per-directory/*) rm -rf ../.state ;; esac
}

check_pulumi() {
  local p=$1 s stacks=() key sc
  cd "$p"
  if [ -n "$(find .pulumi-state -mindepth 1 ! -name .gitkeep -print -quit 2>/dev/null)" ]; then
    warn "$(rel "$p"): has state — run 'make reset' first"; return 1
  fi
  npx --no-install tsc --noEmit
  if node -e 'process.exit(require("./package.json").scripts?.test ? 0 : 1)'; then
    npm test --silent >/dev/null
  fi
  for f in Pulumi.*.yaml; do
    [ -e "$f" ] && { s="${f#Pulumi.}"; stacks+=("${s%.yaml}"); }
  done
  [ ${#stacks[@]} -gt 0 ] || stacks=(dev)
  # `stack init` adds an encryptionsalt to stack files: restore them afterwards
  # (works whether or not they are committed yet).
  local backup; backup="$(mktemp -d)"
  for f in Pulumi.*.yaml; do [ -e "$f" ] && cp "$f" "$backup/"; done
  sc="$(showcase_of "$p")"
  for s in "${stacks[@]}"; do
    pulumi stack init "$s" --non-interactive >/dev/null
    for key in ${PULUMI_CHECK_SECRETS[$sc]:-}; do
      pulumi config set --secret "$key" "$(random_secret)" --non-interactive >/dev/null
    done
    pulumi up --yes --non-interactive --skip-preview >/dev/null
    # A second preview must show no changes.
    pulumi preview --expect-no-changes --non-interactive >/dev/null
    pulumi destroy --yes --non-interactive >/dev/null
    pulumi stack rm "$s" --yes --non-interactive >/dev/null
    rm -f "Pulumi.$s.yaml"
  done
  cp "$backup"/Pulumi.*.yaml . 2>/dev/null || true
  rm -rf "$backup"
  find .pulumi-state -mindepth 1 ! -name .gitkeep -exec rm -rf {} +
}

run() {
  local kind=$1 p=$2
  log "$kind: $(rel "$p")"
  if [ "$HAVE_AWS" = 0 ] && [[ " $AWS_SHOWCASES " == *" $(showcase_of "$p") "* ]]; then
    warn "$(rel "$p"): skipped, needs AWS credentials (aws sts get-caller-identity failed)"
    SKIPPED+=("$(rel "$p")"); return
  fi
  # Not inside `if` or `||`: errexit is ignored in a condition context, even in a subshell.
  local rc
  set +e; ( set -e; "check_$kind" "$p" "${3:-}" ); rc=$?; set -e
  if [ "$rc" = 0 ]; then ok "$(rel "$p")"; else fail "$(rel "$p")"; fi
}

for p in $(tf_projects); do run tf "$p" terraform; done
if command -v tofu >/dev/null; then
  for p in $(tofu_projects); do run tf "$p" tofu; done
fi
for p in $(pulumi_projects); do run pulumi "$p"; done

if [ ${#SKIPPED[@]} -gt 0 ]; then
  printf '\n'; warn "SKIPPED (no AWS credentials):"; printf '  %s\n' "${SKIPPED[@]}" >&2
fi
if [ ${#FAILED[@]} -gt 0 ]; then
  printf '\n'; warn "FAILED:"; printf '  %s\n' "${FAILED[@]}" >&2; exit 1
fi
log "All checks passed."
