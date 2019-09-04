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

ENABLE_EIRINI=false

# get pre_start_script ops files from bazel configuration
pushd "${GIT_ROOT}/scf"
  bazel build //deploy/helm/scf:chart
popd

# Download cf_deployment
cf_deployment_version=8.0.0
cf_deployment_yaml_url=https://raw.githubusercontent.com/cloudfoundry/cf-deployment/v${cf_deployment_version}/cf-deployment.yml
#shasum="1c464acccdd679400005775340ccb69ef8c41d69"

curl -L -o "${GIT_ROOT}/cf-deployment.yml" $cf_deployment_yaml_url
#echo "${shasum} cf-deployment.yml" | sha1sum -c -

# Apply ops files
interpolate_cmd="bosh interpolate ${GIT_ROOT}/cf-deployment.yml  "

search_temporary_ops_dir="${GIT_ROOT}/scf/deploy/helm/scf/assets/operations/temporary/*.yaml"
for file in $search_temporary_ops_dir
do
  interpolate_cmd="${interpolate_cmd}  -o $file  "
done

rsync -a --include '*.yaml' "${GIT_ROOT}/scf/deploy/helm/scf/assets/operations"/ "${GIT_ROOT}/operations"/

rsync -a --include '*.yaml' "${GIT_ROOT}/scf/bazel-bin/bosh/releases"/ "${GIT_ROOT}/pre_start_scripts"/

if [ "$ENABLE_EIRINI" != "true" ];then
  rm "${GIT_ROOT}"/operations/instance_groups/bits-service.yaml
  rm "${GIT_ROOT}"/operations/instance_groups/eirini.yaml
  rm "${GIT_ROOT}"/operations/zz-remove-diego-if-eirini.yaml
  rm -f "${GIT_ROOT}"/pre_start_scripts/eirini_eirini-loggregator-bridge_patch_bpm_sh.yaml
  rm -f "${GIT_ROOT}"/pre_start_scripts/eirini_opi_patch_bpm_sh.yaml
  rm -f "${GIT_ROOT}"/pre_start_scripts/eirini_opi_patch_opi_yml_sh.yaml
  rm -f "${GIT_ROOT}"/pre_start_scripts/bits_bits-service_patch_bits_config_yml_sh.yaml
fi

search_instance_groups_dir="${GIT_ROOT}/operations/instance_groups/*.yaml"
for file in $search_instance_groups_dir
do
  interpolate_cmd="${interpolate_cmd}  -o $file  "
done

search_pre_start_ops_dir="${GIT_ROOT}/pre_start_scripts/*.yaml"
for file in $search_pre_start_ops_dir
do
  interpolate_cmd="${interpolate_cmd}  -o $file  "
done

search_common_ops_dir="${GIT_ROOT}/operations/*.yaml"
for file in $search_common_ops_dir
do
  interpolate_cmd="${interpolate_cmd}  -o $file  "
done

interpolate_cmd="${interpolate_cmd}  -v releases-defaults-url=docker.io/cfcontainerization > cf-base-deployment.yaml"

eval "${interpolate_cmd}"
