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

# Download cf_deployment
cf_deployment_version=8.0.0
cf_deployment_yaml_url=https://raw.githubusercontent.com/cloudfoundry/cf-deployment/v${cf_deployment_version}/cf-deployment.yml
#shasum="1c464acccdd679400005775340ccb69ef8c41d69"

curl -L -o cf-deployment.yml $cf_deployment_yaml_url
#echo "${shasum} cf-deployment.yml" | sha1sum -c -

# Apply ops files
bosh interpolate cf-deployment.yml \
 -o scf/deploy/helm/scf/assets/operations/temporary/remove_roles.yaml \
 -o scf/deploy/helm/scf/assets/operations/temporary/remove_variables.yaml \
 -o scf/deploy/helm/scf/assets/operations/instance_groups/adapter.yaml \
 -o scf/deploy/helm/scf/assets/operations/instance_groups/api.yaml \
 -o scf/deploy/helm/scf/assets/operations/instance_groups/cc-worker.yaml \
 -o scf/deploy/helm/scf/assets/operations/instance_groups/database.yaml \
 -o scf/deploy/helm/scf/assets/operations/instance_groups/diego-api.yaml \
 -o scf/deploy/helm/scf/assets/operations/instance_groups/diego-cell.yaml \
 -o scf/deploy/helm/scf/assets/operations/instance_groups/doppler.yaml \
 -o scf/deploy/helm/scf/assets/operations/instance_groups/log-api.yaml \
 -o scf/deploy/helm/scf/assets/operations/instance_groups/nats.yaml \
 -o scf/deploy/helm/scf/assets/operations/instance_groups/router.yaml \
 -o scf/deploy/helm/scf/assets/operations/instance_groups/scheduler.yaml \
 -o scf/deploy/helm/scf/assets/operations/instance_groups/singleton-blobstore.yaml \
 -o scf/deploy/helm/scf/assets/operations/instance_groups/uaa.yaml \
 -o scf/deploy/helm/scf/assets/operations/addons.yaml \
 -o scf/deploy/helm/scf/assets/operations/certs.yaml \
 -o scf/deploy/helm/scf/assets/operations/set_opensuse_stemcells.yaml \
 -o scf/deploy/helm/scf/assets/operations/set_release_urls.yaml \
 -o scf/deploy/helm/scf/assets/operations/set_release_versions.yaml \
 -v releases-defaults-url=docker.io/cfcontainerization

# TODO How to extract and apply pre_start.sh from bazel configuration

script_files="scf/bosh/releases/pre_render_scripts/**/*.sh"

function pre_render_script_ops() {
    export INSTANCE_GROUP=$1
    export JOB=$2
    export TYPE=$3
    export PRE_RENDER_SCRIPT=$PRE_RENDER_SCRIPT=$4
    export OUTPUT=$5
    echo "Generating pre_render_script ops-file $OUTPUT"
    scf/bosh/releases/generators/pre_render_scripts/generator.sh
    return 0
}
