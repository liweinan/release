#!/bin/bash

set -o nounset
set -o errexit
set -o pipefail

CONFIG="${SHARED_DIR}/install-config.yaml"

# 如果指定了自定义region，则使用它；否则使用默认的LEASED_RESOURCE
if [[ -n "${CUSTOM_AWS_REGION:-}" ]]; then
  REGION="${CUSTOM_AWS_REGION}"
  echo "Using custom AWS region: ${REGION}"
else
  REGION="${LEASED_RESOURCE}"
  echo "Using default AWS region: ${REGION}"
fi

# 创建region配置patch
PATCH="${SHARED_DIR}/install-config-custom-region.yaml.patch"
cat > "${PATCH}" << EOF
platform:
  aws:
    region: ${REGION}
EOF

echo "Applying custom region configuration: ${REGION}"
yq-go m -x -i "${CONFIG}" "${PATCH}"
rm "${PATCH}" 