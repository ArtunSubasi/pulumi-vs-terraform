#!/usr/bin/env bash
# The KMS key both tools encrypt with. It lives outside both projects on purpose: the key
# has to exist before the first state file (or stack) that is encrypted with it.
#
#   ./key.sh create    create the key + alias if missing (idempotent), print the key ARN
#                      and the matching `pulumi stack init --secrets-provider` value
#   ./key.sh delete    remove the alias, schedule the key for deletion (7 days, the minimum)
#
# Destroy both projects first: state encrypted with a deleted key can't be read anymore.
# Costs: ~1 USD/month while the key exists, plus API calls.
set -euo pipefail

ALIAS="alias/tf-vs-pulumi-demo"

key_id() { aws kms describe-key --key-id "$ALIAS" --query KeyMetadata.KeyId --output text 2>/dev/null; }

case "${1:-}" in
  create)
    if ! key_id >/dev/null; then
      id="$(aws kms create-key --description "tf-vs-pulumi demo: state encryption" \
        --tags TagKey=demo,TagValue=tf-vs-pulumi --query KeyMetadata.KeyId --output text)"
      aws kms create-alias --alias-name "$ALIAS" --target-key-id "$id"
    fi
    arn="$(aws kms describe-key --key-id "$ALIAS" --query KeyMetadata.Arn --output text)"
    region="$(cut -d: -f4 <<<"$arn")"   # arn:aws:kms:<region>:<account>:key/<id>
    echo "Key ARN:  $arn"
    echo "Pulumi:   pulumi stack init dev --secrets-provider \"awskms:///$arn?region=$region\""
    ;;
  delete)
    id="$(key_id)" || { echo "$ALIAS not found" >&2; exit 1; }
    aws kms delete-alias --alias-name "$ALIAS"
    aws kms schedule-key-deletion --key-id "$id" --pending-window-in-days 7 \
      --query DeletionDate --output text
    ;;
  *)
    echo "usage: $0 create|delete" >&2; exit 2
    ;;
esac
