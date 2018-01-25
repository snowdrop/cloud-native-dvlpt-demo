# Instructions

## Prerequisite

- MiniShift created with 5Gb, OCP 3.7

```bash

```

- Add your own Github booster to the catalog

```bash
git clone git@github.com:cmoulliard/booster-catalog.git && cd booster-catalog
mkdir -p jpa/spring-boot/community
touch jpa/spring-boot/community/spring-boot-jpa-community.yaml
# echo to the file (TODO)
githubRepo: https://github.com/cmoulliard/spring-boot-jpa-rest
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

- Launcher installed

```bash
./deploy_launcher.sh -p my-launcher -i admin:admin \
                     -g cmoulliard:0c19e98e0fab52588c615d07ea32f3d7afc61ee0 \
                     -c https://github.com/cmoulliard/booster-catalog.git
```

- Istio 0.4.0 installed

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
- Ansible Service Catalog installed

```bash

```

## Test Launcher

Open the `launcher` route hostname

```bash
LAUNCH_URL="http://$(oc get route/launchpad-nginx -n my-launcher -o jsonpath="{.spec.host}")"
open $LAUNCH_URL
```

## Demo Scenario

1) Demo DevTooling (= Fmp, /launcher, s2i build)

- we use /launcher to select a Spring Boot app, a mission
- download the zip, unzip, 
- create a project on OCP, 
- then start fmp to do s2i build on OCP (show to the user what happen using OCP UI)

2) Demo Services offered by the platform (= Service Discovery, Service Catalog), TO BE VALIDATED,

- Select another mission from the /launcher = could be this project adapted -> https://github.com/cmoulliard/spring-boot-jpa-rest/
- Download/unzip/deploy 
- Appply service yaml files to bind to a DB. 
- Change the first microservice to let it to access the second

Then now we have 3 apps running on the platform

3) Demo routing feature (= Istio = ServiceMesh) 
add a route or policy and show what changed to the user



