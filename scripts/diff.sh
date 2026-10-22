#!/usr/bin/env bash
# Show what will be typed live: `diff -r final live` per showcase and tool,
# plus a count of changed lines (the target is ~5–10 per tool and showcase).
set -euo pipefail
source "$(dirname "$0")/lib.sh"

EXCLUDES=(-x .terraform -x '*.tfstate*' -x terraform.tfstate.d -x .terraform.lock.hcl
          -x node_modules -x sdks -x bin -x .pulumi-state -x out -x 'Pulumi.*.yaml')

for s in $(showcases); do
  for tool in terraform pulumi opentofu; do
    [ -d "$s/$tool/final" ] && [ -d "$s/$tool/live" ] || continue
    out="$(diff -r "${EXCLUDES[@]}" "$s/$tool/final" "$s/$tool/live" || true)"
    n="$(grep -c '^<' <<<"$out" || true)"
    log "$(rel "$s")/$tool — $n line(s) to type"
    [ -n "$out" ] && echo "$out"
  done
done
