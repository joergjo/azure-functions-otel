#!/bin/bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
harness_root="${repository_root}/.destroy-terraform-harness"

cleanup() {
  rm -rf "$harness_root"
}
trap cleanup EXIT

mkdir -p "$harness_root/bin" "$harness_root/infra/terraform"
cp "$repository_root/destroy-terraform.sh" "$harness_root/destroy-terraform.sh"
printf '{}\n' >"$harness_root/infra/terraform/terraform.tfstate"

cat >"$harness_root/bin/az" <<'EOF'
#!/bin/bash
printf '%s\n' '{"subscriptionId":"test-subscription","tenantId":"test-tenant"}'
EOF

cat >"$harness_root/bin/terraform" <<'EOF'
#!/bin/bash
case "${1:-}" in
  init | fmt | validate)
    exit 0
    ;;
  show)
    if [ "${HARNESS_MODE:-}" = "forbidden-delete" ] &&
      [ "${3:-}" = ".terraform/destroy.tfplan" ]; then
      printf '%s\n' "$HARNESS_PLAN_JSON"
    else
      printf '%s\n' "$HARNESS_STATE_JSON"
    fi
    ;;
  plan)
    if [ "${HARNESS_MODE:-}" = "forbidden-delete" ]; then
      exit 0
    fi
    if [ -n "${TF_CLI_ARGS_plan+x}" ]; then
      echo "TF_CLI_ARGS_plan reached terraform plan." >&2
      exit 98
    fi
    for argument in "$@"; do
      if [ "$argument" = "-target=azurerm_resource_group.this" ]; then
        echo "The resource-group target reached terraform plan." >&2
        exit 97
      fi
    done
    echo "PLAN_REACHED_WITHOUT_AMBIENT_RESOURCE_GROUP_TARGET"
    exit 77
    ;;
  apply)
    echo "terraform apply must not run in this harness." >&2
    exit 96
    ;;
  *)
    echo "Unexpected terraform command: $*" >&2
    exit 99
    ;;
esac
EOF

chmod +x \
  "$harness_root/bin/az" \
  "$harness_root/bin/terraform" \
  "$harness_root/destroy-terraform.sh"

state_json='{"values":{"root_module":{"child_modules":[{"resources":[{"address":"module.storage.azurerm_storage_account.collector_config","mode":"managed","values":{"id":"/subscriptions/test-subscription/resourceGroups/test-rg/providers/Microsoft.Storage/storageAccounts/example","resource_group_name":"test-rg"}}]}]}}}'
output_file="$harness_root/output.txt"

set +e
(
  cd "$harness_root"
  PATH="$harness_root/bin:/usr/bin:/bin" \
    FUNCTIONS_RESOURCE_GROUP_NAME="test-rg" \
    HARNESS_STATE_JSON="$state_json" \
    TF_CLI_ARGS_plan="-target=azurerm_resource_group.this" \
    ./destroy-terraform.sh
) >"$output_file" 2>&1
status=$?
set -e

if [ "$status" -ne 77 ] ||
  ! grep -Fq "PLAN_REACHED_WITHOUT_AMBIENT_RESOURCE_GROUP_TARGET" "$output_file"; then
  cat "$output_file" >&2
  echo "Ambient Terraform argument harness failed with status ${status}." >&2
  exit 1
fi

echo "PASS: TF_CLI_ARGS_plan cannot inject the resource-group target."

plan_json='{"resource_changes":[{"address":"azurerm_resource_group.this","change":{"actions":["delete"]}}]}'

set +e
(
  cd "$harness_root"
  PATH="$harness_root/bin:/usr/bin:/bin" \
    FUNCTIONS_RESOURCE_GROUP_NAME="test-rg" \
    HARNESS_MODE="forbidden-delete" \
    HARNESS_STATE_JSON="$state_json" \
    HARNESS_PLAN_JSON="$plan_json" \
    ./destroy-terraform.sh
) >"$output_file" 2>&1
status=$?
set -e

if [ "$status" -ne 1 ] ||
  ! grep -Fq "outside the six allowed modules" "$output_file"; then
  cat "$output_file" >&2
  echo "Forbidden root-resource deletion harness failed with status ${status}." >&2
  exit 1
fi

echo "PASS: a saved plan deleting azurerm_resource_group.this is rejected."
