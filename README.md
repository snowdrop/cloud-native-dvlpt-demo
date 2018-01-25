# Instructions

## Prerequisite

- MiniShift created with OCP 3.7.1 and launched using experimental features

```bash
ISTIO_VERSION=${1:-0.4.0}
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
)
IMAGES=$(printf "%s " "${docker_images[@]}")
minishift profile set istio
minishift --profile istio config set memory 4GB
minishift --profile istio config set openshift-version v3.7.1
minishift --profile istio config set vm-driver xhyve
minishift --profile istio addon enable admin-user
minishift config set image-caching true
minishift image cache-config add $IMAGES
export MINISHIFT_ENABLE_EXPERIMENTAL=y
minishift start --profile istio --service-catalog
```

- Add your own Github booster(s) to the catalog

```bash
git clone git@github.com:cmoulliard/booster-catalog.git && cd booster-catalog
mkdir -p jpa/spring-boot/community
touch jpa/spring-boot/community/spring-boot-jpa-community.yaml
# echo to the file (TODO)
githubRepo: cmoulliard/spring-boot-jpa-rest
gitRef: master

# echo edit metadata
{
    "missions":[
        {"id": "jpa", "name":"JPA Persistence"},
        {"id": "configmap", "name":"Externalized Configuration"},
        {"id": "crud", "name":"CRUD"},
        {"id": "health-check", "name":"Health Check"},
        {"id": "rest-http", "name":"REST API Level 0"},
        {"id": "rest-http-secured", "name":"Secured"},
        {"id": "circuit-breaker", "name":"Circuit Breaker"}
    ],
...    
git commit -m "Changes" -a
git push    
```

- Create your "my-Launcher"

```bash
./deploy_launcher.sh -p my-launcher -i admin:admin \
                     -g user:xxxx \
                     -v master \
                     -c https://github.com/cmoulliard/booster-catalog.git
```

- Install Istio 0.4.0

```bash
pushd $(mktemp -d)
echo "Git clone ansible project to install istio distro, project on openshift"
git clone https://github.com/istio/istio.git && cd istio/install/ansible

export ISTIO_VERSION=0.4.0 #or whatever version you prefer
export JSON='{"cluster_flavour": "ocp","istio": {"release_tag_name": "0.4.0, "auth": false}}'
echo "$JSON" > temp.json
ansible-playbook main.yml -e "@temp.json"
rm temp.json
```
- Install Ansible Service Catalog

```bash
oc new-project ansible-service-broker
curl -s https://raw.githubusercontent.com/openshift/ansible-service-broker/master/templates/simple-broker-template.yaml | oc process -n "ansible-service-broker" -f - | oc create -f -
```

## Test Launcher

Open the `launcher` route hostname

```bash
LAUNCH_URL="http://$(oc get route/launchpad-nginx -n my-launcher -o jsonpath="{.spec.host}")"
open $LAUNCH_URL
```

## Demo Scenario

1) Demo DevTooling (= Fmp, /launcher, s2i build)

- We use `/launcher` to select Spring Boot Mission `JPA Client`
- The project generated is downloaded, unzipped, 
- Then, we create a new project on OCP `my-demo`, 
- Then we build the project to deploy it
```bash
mvn package fabric8:deploy
```

2) Demo Services offered by the platform (= Service Discovery, Service Catalog), TO BE VALIDATED,

- Select another mission from the /launcher = could be this project adapted -> https://github.com/cmoulliard/spring-boot-jpa-rest/
- Download/unzip/deploy 
- Appply service yaml files to bind to a DB. 
- Change the first microservice to let it to access the second

Then now we have 3 apps running on the platform

3) Demo routing feature (= Istio = ServiceMesh) 
add a route or policy and show what changed to the user



