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

# 创建region配置patch，使用更强的合并策略
PATCH="${SHARED_DIR}/install-config-custom-region.yaml.patch"
cat > "${PATCH}" << EOF
platform:
  aws:
    region: ${REGION}
EOF

echo "Applying custom region configuration: ${REGION}"
# 使用yq的merge策略，确保我们的设置不会被覆盖
yq-go m -x -i "${CONFIG}" "${PATCH}"

# 验证region是否被正确设置
ACTUAL_REGION=$(yq-go r "${CONFIG}" 'platform.aws.region')
echo "Actual region in install-config.yaml: ${ACTUAL_REGION}"

if [[ "${ACTUAL_REGION}" != "${REGION}" ]]; then
  echo "ERROR: Region mismatch! Expected: ${REGION}, Actual: ${ACTUAL_REGION}"
  exit 1
fi

rm "${PATCH}" 