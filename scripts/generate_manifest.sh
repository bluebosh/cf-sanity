#!/bin/bash
#
# ########################################################### {COPYRIGHT-TOP} ####
# # Licensed Materials - Property of IBM
# # IBM Cloud
# #
# # (C) Copyright IBM Corp. 2019
# #
# # US Government Users Restricted Rights - Use, duplication, or
# # disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
# ########################################################### {COPYRIGHT-END} ####
#

set -eEu -o pipefail
shopt -s extdebug

GIT_ROOT=${GIT_ROOT:-$(git rev-parse --show-toplevel)}

echo "[INFO] Build helm chart over bazel"
pushd "${GIT_ROOT}/kubecf"
  bazel build //deploy/helm/kubecf:chart
popd

echo "[INFO] Render helm templates"
tar zxf kubecf/bazel-bin/deploy/helm/kubecf/kubecf-3.0.0.tgz -C helm/
helm template helm/kubecf/ --output-dir ./templates

echo "[INFO] Generate ops file"
yq -r .data.manifest ./templates/kubecf/templates/cf_deployment.yaml > ./manifests/cf_base_deployment.yaml

# Start with 1 to skip first empty doc
yq -rs ".[1].data.ops" ./templates/kubecf/templates/single_availability.yaml > ./operations/single_availability.yaml

ops_file=templates/kubecf/templates/ops.yaml
length=$(yq -s '. | length' ${ops_file})
# Start with 1 to skip first empty doc
count=1
echo > ./operations/ops.yaml
while [ "${count}" -lt "${length}" ]; do
  yq -rs ".[${count}].data.ops" "${ops_file}" >> ./operations/ops.yaml

  count=$(( count + 1 ))
done

echo "[INFO] Interpolate ops file"
bosh interpolate ./manifests/cf_base_deployment.yaml \
  -o ./operations/ops.yaml \
  -o ./operations/single_availability.yaml \
  >  ./manifests/cf_deployment.yaml

spruce merge spruce-config/cf_deployment_configmap.yaml > ./deploy/100-cf-deployment.yaml
