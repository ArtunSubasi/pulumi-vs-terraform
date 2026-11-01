#!/usr/bin/env bash
# Wipe all demo state so every showcase starts from zero.
#
#   reset.sh          state, .terraform/, workspaces, plans, generated files, Pulumi stacks
#   reset.sh --live   additionally restores every live/ dir to its committed version
#                     (throws away whatever was typed during a rehearsal)
#
# 01-bootstrap/pulumi/live is deleted entirely by --live (`pulumi new` needs an empty target).
# Keeps node_modules/ and the provider mirror, so `make prep` afterwards is quick and offline.
set -euo pipefail
source "$(dirname "$0")/lib.sh"

LIVE=0
[ "${1:-}" = "--live" ] && LIVE=1

log "Terraform / OpenTofu"
for p in $(tf_projects) $(tofu_projects); do
  rm -rf "$p"/.terraform "$p"/terraform.tfstate* "$p"/terraform.tfstate.d "$p"/*.tfplan "$p"/out
  # env-per-directory/prod keeps its state outside the root (../.state)
  case "$p" in */env-per-directory/*) rm -rf "$p/../.state" ;; esac
  # Nested test fixtures / local modules may write files too
  find "$p" -type d -name out -not -path '*/node_modules/*' -prune -exec rm -rf {} +
  ok "$(rel "$p")"
done

log "Pulumi"
for p in $(pulumi_projects); do
  find "$p/.pulumi-state" -mindepth 1 ! -name .gitkeep -exec rm -rf {} + 2>/dev/null || true
  rm -rf "$p"/bin "$p"/out
  # Stack files: committed ones go back to their committed (salt-free) version.
  # Uncommitted ones are removed only if Pulumi generated them (salt / secrets inside).
  for f in "$p"/Pulumi.*.yaml; do
    [ -e "$f" ] || continue
    if git -C "$p" ls-files --error-unmatch "$(basename "$f")" >/dev/null 2>&1; then
      git -C "$p" checkout -q -- "$(basename "$f")"
    elif grep -qE '^encryptionsalt:|^encryptedkey:|secure:' "$f"; then
      rm -f "$f"
    fi
  done
  ok "$(rel "$p")"
done

if [ "$LIVE" = 1 ]; then
  log "Restoring live/ dirs to their committed state"
  # 01: `pulumi new --dir live` creates this dir on stage, so it must not exist beforehand.
  rm -rf "$REPO_ROOT/01-bootstrap/pulumi/live"
  for s in $(showcases); do
    for d in "$s"/*/live; do
      [ -d "$d" ] || continue
      if [ -n "$(git -C "$REPO_ROOT" ls-files -- "$(rel "$d")")" ]; then
        git -C "$REPO_ROOT" checkout -q -- "$(rel "$d")"
      fi
      git -C "$REPO_ROOT" clean -fdq -- "$(rel "$d")"   # untracked, but keeps ignored (node_modules)
      ok "$(rel "$d")"
    done
  done
fi
