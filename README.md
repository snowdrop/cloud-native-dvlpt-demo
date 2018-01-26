# Instructions

## Prerequisite

- MiniShift created with OCP 3.7.1 and launched using experimental features

```bash
./bootstrap_vm.sh
```

- Install your "my-Launcher"

**NOTE** : Replace the `gitUsername` and `gitPassword` parameters with your `github account` and `git token` in ordet to let the launcher to create a git repo within your org.

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

## Test Launcher

Open the `launcher` route hostname

```bash
LAUNCH_URL="http://$(oc get route/launchpad-nginx -n my-launcher -o jsonpath="{.spec.host}")"
open $LAUNCH_URL
```

## Istio

Install Istio 0.4.0

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

## Demo Scenario

1) Use launcher to generate a front zip

- Use `/launcher` to select Spring Boot Mission `Cloud Native Demo Front`

TODO

2) Create a MySQL service instance using the Service Catalog

! Use the Web UI to create the Service and bind it. Alternatively, execute the following commands with the backend folder

1. Create a Service Instance

```bash
oc create -f openshift/mysql_serviceinstance.yml
```

5. Create a new app on the cloud platform

```bash
oc new-app -f openshift/spring-boot-db-notes_template.yml
```

6. Start the build using project's source

```bash
oc start-build spring-boot-db-notes-s2i --from-dir=. --follow
```

7. Bind the credentials of the ServiceInstances to a Secret

The following file will allow to access the credentials of the MySQL ServiceInstance. Upon creation, the Service Catalog controller will create a Kubernetes Secret containing connection details
and credentials for the Service Instance, which can be mounted into Pods.

```bash
oc create -f openshift/mysql-secret_servicebinding.yml
```

3) Use launcher to generate a backend zip
   
- Use `/launcher` to select Spring Boot Mission `Cloud Native Demo Backend`

- The project generated is downloaded, unzipped 
```bash
mkdir -p cloud-native-demo
cd cloud-native-demo
mv /Users/dabou/Downloads/booster-demo-backend-spring-boot.zip .
unzip booster-demo-backend-spring-boot.zip
cd booster-demo-backend-spring-boot
```
- Test it locally
```bash
mvn clean spring-boot:run -Dspring.profiles.active=local -Ph2
curl -k http://localhost:8080/api/notes 
curl -k -H "Content-Type: application/json" -X POST -d '{"title":"My first note","content":"Spring Boot is awesome!"}' http://localhost:8080/api/notes 
curl -k http://localhost:8080/api/notes/1
```
- Create a new OpenShift project on OCP
```bash
oc new-project cnd-demo
```
- Deploy it using `s2i` build process
```bash
mvn package fabric8:deploy -Popenshift
```

- Wait till the build and deployment is completed !!
- Next, mount the secret of the MySQL service to the `Deploymentconfig` of the backend

```bash
oc env --from=secret/spring-boot-notes-mysql-binding dc/spring-boot-db-notes
```

- Wait till the pod is recreated and then test the service

```bash
export HOST=$(oc get route/spring-boot-db-notes -o jsonpath='{.spec.host}')
curl -k $HOST/api/notes 
curl -k -H "Content-Type: application/json" -X POST -d '{"title":"My first note","content":"Spring Boot is awesome!"}' $HOST/api/notes 
curl -k $HOST/api/notes/1
```



