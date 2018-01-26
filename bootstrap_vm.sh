#!/usr/bin/env bash

ISTIO_PROFILE_DIR="$HOME/.minishift/profiles/istio"
ISTIO_VERSION=${1:-0.4.0}
OCP_VERSION=${2:-3.7.1}

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
)
IMAGES=$(printf "%s " "${docker_images[@]}")

if [ ! -d "$ISTIO_PROFILE_DIR" ]; then
  minishift profile set istio
  minishift --profile istio config set memory 5GB
  minishift --profile istio config set openshift-version v$OCP_VERSION
  minishift --profile istio config set vm-driver xhyve
  minishift --profile istio addon enable admin-user
fi

minishift config set image-caching true
minishift image cache-config add $IMAGES

minishift start --profile istio
#MINISHIFT_ENABLE_EXPERIMENTAL=y minishift start --profile istio --service-catalog

# Export images to be sure to have a backup locally
minishift image export

echo "Log to OpenShift using admin user"
oc login -u system:admin
oc adm policy add-cluster-role-to-user cluster-admin admin

minishift stop --profile istio

# Let's do that as we can't install the service catalog during
MINISHIFT_ENABLE_EXPERIMENTAL=y minishift start --profile istio --service-catalog
oc login -u admin -p admin
