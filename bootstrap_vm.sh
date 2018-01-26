#!/usr/bin/env bash

#
# Command Usage
# ./bootstrap_vm.sh [COMMANDS]
#
# where commands are:
# istio version       Version of istio to be used. Default to 0.4.0
# ocp version         Version of OpenShift Origin. Default to : 3.7.1
# imageCache          Enable or disable to use docker images cached on the local user's disk. Default is false
#
# ./bootstrap_vm.sh 0.4.0 3.7.1 true
#

ISTIO_PROFILE_DIR="$HOME/.minishift/profiles/istio"
ISTIO_VERSION=${1:-0.4.0}
OCP_VERSION=${2:-3.7.1}
IMAGE_CACHE=${3:-false}

docker_images=(
  istio/istio-ca:$ISTIO_VERSION
  istio/grafana:$ISTIO_VERSION
  istio/pilot:$ISTIO_VERSION
  istio/proxy_debug:$ISTIO_VERSION
  istio/proxy_init:$ISTIO_VERSION
  istio/mixer:$ISTIO_VERSION
  istio/servicegraph:$ISTIO_VERSION
  prom/statsd-exporter:v0.5.0
  prom/prometheus:v2.0.0
  alpine:latest
  jaegertracing/all-in-one:latest
  openshift/origin-docker-registry:v$OCP_VERSION
  openshift/origin-haproxy-router:v$OCP_VERSION
  openshift/origin-deployer:v$OCP_VERSION
  openshift/origin:v$OCP_VERSION
  openshift/origin-pod:v$OCP_VERSION
  openshift/origin-sti-builder:v$OCP_VERSION
  fabric8/s2i-java:2.0
  fabric8/configmapcontroller:2.3.7
  registry.access.redhat.com/redhat-openjdk-18/openjdk18-openshift:latest
  quay.io/coreos/etcd:latest
  ansibleplaybookbundle/origin-ansible-service-broker:latest
  openshiftio/launchpad-backend:v12
  openshiftio/launchpad-frontend:v12
  openshiftio/launchpad-missioncontrol:v13
  registry.access.redhat.com/rhscl/mysql-57-rhel7:latest
)
IMAGES=$(printf "%s " "${docker_images[@]}")

if [ ! -d "minishift-addons" ]; then
  git clone -b asb-updates https://github.com/eriknelson/minishift-addons.git
fi

if [ ! -d "$ISTIO_PROFILE_DIR" ]; then
  minishift profile set istio
  minishift --profile istio addons install minishift-addons/add-ons/ansible-service-broker
  minishift --profile istio config set memory 5GB
  minishift --profile istio config set openshift-version v$OCP_VERSION
  minishift --profile istio config set vm-driver xhyve
  minishift --profile istio addon enable admin-user
  minishift --profile istio addon enable ansible-service-broker
fi

# minishift config set image-caching true
#
# if [ "$IMAGE_CACHE" = true ] ; then
#   minishift image cache-config add $IMAGES
# fi
#
# MINISHIFT_ENABLE_EXPERIMENTAL=y minishift start --profile istio --service-catalog --iso-url centos
#
# if [ "$IMAGE_CACHE" = true ] ; then
#   # Export images to be sure to have a backup locally
#   minishift image export
# fi
#
# echo "Log to OpenShift using admin user"
# oc login -u system:admin
# oc adm policy add-cluster-role-to-user cluster-admin admin
# oc login -u admin -p admin
