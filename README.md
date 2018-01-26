# Instructions

## Prerequisite

- MiniShift created with OCP 3.7.1 and launched using experimental features

```bash
./bootstrap_vm.sh
```

- Install your "my-Launcher"

Replace the `gitUsername` and `gitPassword` with youor github account and git token.

```bash
./deploy_launcher.sh -p my-launcher \
                     -i admin:admin \
                     -g gitUsername:gitPassword \
                     -c https://github.com/snowdrop/cloud-native-catalog.git
```

- Install Ansible Service Catalog

```bash
oc new-project ansible-service-broker
curl -s https://raw.githubusercontent.com/openshift/ansible-service-broker/master/templates/simple-broker-template.yaml | oc process -n "ansible-service-broker" -f - | oc create -f -
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



