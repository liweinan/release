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

# 根据region设置对应的zones
case "${REGION}" in
  "ap-east-2")
    ZONES="ap-east-2a,ap-east-2b"
    ;;
  "us-east-1")
    ZONES="us-east-1a,us-east-1b"
    ;;
  "us-east-2")
    ZONES="us-east-2a,us-east-2b"
    ;;
  "us-west-1")
    ZONES="us-west-1a,us-west-1b"
    ;;
  "us-west-2")
    ZONES="us-west-2a,us-west-2b"
    ;;
  *)
    # 对于其他region，使用前两个zones
    ZONES="${REGION}a,${REGION}b"
    ;;
esac

echo "Using zones for region ${REGION}: ${ZONES}"

# 创建region和zones配置patch
PATCH="${SHARED_DIR}/install-config-custom-region.yaml.patch"
cat > "${PATCH}" << EOF
platform:
  aws:
    region: ${REGION}
controlPlane:
  platform:
    aws:
      zones:
      - ${REGION}a
      - ${REGION}b
compute:
- platform:
    aws:
      zones:
      - ${REGION}a
      - ${REGION}b
EOF

echo "Applying custom region and zones configuration: ${REGION}"
# 使用yq的merge策略，确保我们的设置不会被覆盖
yq-go m -x -i "${CONFIG}" "${PATCH}"

# 验证region是否被正确设置
ACTUAL_REGION=$(yq-go r "${CONFIG}" 'platform.aws.region')
echo "Actual region in install-config.yaml: ${ACTUAL_REGION}"

if [[ "${ACTUAL_REGION}" != "${REGION}" ]]; then
  echo "ERROR: Region mismatch! Expected: ${REGION}, Actual: ${ACTUAL_REGION}"
  exit 1
fi

# 验证zones是否被正确设置
ACTUAL_CONTROL_PLANE_ZONES=$(yq-go r "${CONFIG}" 'controlPlane.platform.aws.zones' | tr '\n' ',' | sed 's/,$//')
echo "Actual control plane zones: ${ACTUAL_CONTROL_PLANE_ZONES}"

EXPECTED_ZONES="${REGION}a,${REGION}b"
if [[ "${ACTUAL_CONTROL_PLANE_ZONES}" != "${EXPECTED_ZONES}" ]]; then
  echo "ERROR: Zones mismatch! Expected: ${EXPECTED_ZONES}, Actual: ${ACTUAL_CONTROL_PLANE_ZONES}"
  exit 1
fi

rm "${PATCH}" 