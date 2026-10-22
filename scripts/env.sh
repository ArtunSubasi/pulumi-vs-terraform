# Source this in every demo terminal:   source scripts/env.sh
#
# - Points Terraform AND OpenTofu at the offline provider mirror built by `make prep`,
#   so `init` works without network on stage.
# - Silences Pulumi's update check.
# It does NOT set PULUMI_CONFIG_PASSPHRASE. Enter it when prompted, or export it yourself.

_af_root="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"

if [ -f "$_af_root/.cache/cli.tfrc" ]; then
  export TF_CLI_CONFIG_FILE="$_af_root/.cache/cli.tfrc"
  echo "Terraform/OpenTofu: offline mirror ($TF_CLI_CONFIG_FILE)"
else
  echo "Terraform/OpenTofu: no offline mirror yet. Run 'make prep' (needs network once)."
fi

export PULUMI_SKIP_UPDATE_CHECK=true
[ -n "${PULUMI_CONFIG_PASSPHRASE:-}" ] || echo "Pulumi: PULUMI_CONFIG_PASSPHRASE not set — you'll be prompted."

unset _af_root
