# Instructions

## Prerequisite

- MiniShift created with Openshift Origin 3.7.1, using `ansible-service-broker` addon and started using experimental features

The following invocation of `bootstrap_vm.sh <image_cache> <ocp_version>` sets up a `demo` profile, new vm, install the docker images
within the registry according to the ocp version defined

```bash
./bootstrap_vm.sh true 3.7.1
```

**NOTE** : The minishift `ansible-service-broker` addon is based on this project `https://github.com/eriknelson/minishift-addons` and branch `asb-updates`

**NOTE** : When the vm has been created, then it can be stopped/started using the commands `minishift stop|start --profile demo`

- Install your "my-Launcher"

**NOTE** : Replace the `gitUsername` and `gitPassword` parameters with your `github account` and `git token` in order to let the launcher to create a git repo within your org.

```bash
./deploy_launcher.sh -p my-launcher \
                     -i admin:admin \
                     -g gitUsername:gitPassword \
                     -c https://github.com/snowdrop/cloud-native-catalog.git \
                     -b master
```

## Test Launcher

Open the `launcher` route hostname

```bash
# LAUNCH_URL="http://$(oc get route/launchpad-nginx -n my-launcher -o jsonpath="{.spec.host}")"
LAUNCH_URL=$(minishift openshift service launchpad-nginx -n my-launcher --url)
open $LAUNCH_URL
```

## Demo Scenario

1) Use launcher to generate a Cloud Native Demo - Front zip

- From the `launcher application` screen, click on `launch` button

![](image/launcher.png)

- Within the deployment type screen, click on the button `I will build and run locally`
- Next, select your mission : `Cloud Native Development - Demo Front`

![](image/missions.png)

- Choose `Spring Boot Runtime`
- Accept the `Project Info`
- Finally click on the button Select `Download as zip file`
- Unzip the generated project
```bash
mkdir -p cloud-native-demo
cd cloud-native-demo
mv ~/Downloads/booster-demo-front-spring-boot.zip .
unzip booster-demo-front-spring-boot.zip
cd booster-demo-front-spring-boot
```

- Build and launch spring-boot application locally to ensure the application can be used in your browser
```bash
mvn clean spring-boot:run 
open http://localhost:8090
```
- Create a new OpenShift project on OCP
```bash
oc new-project cnd-demo
```
- Deploy the application on the cloud platform using the `s2i` build process
```bash
mvn package fabric8:deploy -Popenshift
```

2) Create a MySQL service instance using the Service Catalog

! Use the Web UI to create the Service and bind it. 
Alternatively, execute the following command using the definition file provided with the backend application (which is the subject of the next step) in order to create a serviceInstance for MySQL

```bash
oc create -f openshift/mysql_serviceinstance.yml
```


3) Use launcher to generate a Cloud Native Demo - Backend zip
   
- From the first screen, click on `launch` button
- Within the deployment type screen, click on the button `I will build and run locally`
- Next, select your mission : `Cloud Native Development - Demo Backend : JPA Persistence`

![](image/missions.png)

- Choose the `Spring Boot Runtime`
- Accept the `Project Info`
- Finally click on the button Select `Download as zip file`
- Unzip the project generated
```bash
cd cloud-native-demo
mv ~/Downloads/booster-demo-backend-spring-boot.zip .
unzip booster-demo-backend-spring-boot.zip
cd booster-demo-backend-spring-boot
```
- Build, launch spring-boot locally to test the in-memory H2 database
```bash
mvn clean spring-boot:run -Ph2 -Drun.arguments="--spring.profiles.active=local,--jaeger.sender=http://jaeger-collector-tracing.192.168.64.85.nip.io/api/traces,--jaeger.protocol=HTTP,--jaeger.port=0"
curl -k http://localhost:8080/api/notes 
curl -k -H "Content-Type: application/json" -X POST -d '{"title":"My first note","content":"Spring Boot is awesome!"}' http://localhost:8080/api/notes 
curl -k http://localhost:8080/api/notes/1
```

- Deploy the application on the cloud platform using the `s2i` build process
```bash
oc new-app -f openshift/cloud-native-demo_backend_template.yml
```

- Start the build using project's source
  
```bash
oc start-build cloud-native-backend-s2i --from-dir=. --follow
```
- Wait until the build and deployment complete !!

- Bind the credentials of the ServiceInstances to a Secret

```bash
oc create -f openshift/mysql-secret_servicebinding.yml
```

- Next, mount the secret of the MySQL service to the `Deploymentconfig` of the backend

```bash
oc env --from=secret/spring-boot-notes-mysql-binding dc/cloud-native-backend
```

**NOTE**: If you create the service using the UI, then find the secret name of the DB and next click on the `add to application` button
to add the secret to the Deployment Config of your application

- Wait until the pod is recreated and then test the service

![](image/front-db.png)

```bash
#export BACKEND=$(oc get route/cloud-native-backend -o jsonpath='{.spec.host}' -n cnd-demo)
export BACKEND=$(minishift openshift service cloud-native-backend -n cnd-demo --url)
curl -k $BACKEND/api/notes 
curl -k -H "Content-Type: application/json" -X POST -d '{"title":"My first note","content":"Spring Boot is awesome!"}' $BACKEND/api/notes 
curl -k $BACKEND/api/notes/1
```
## Enable OpenTracing

1. Install Jaeger on OpenShift to collect the traces

```bash
oc new-project tracing
oc process -f https://raw.githubusercontent.com/jaegertracing/jaeger-openshift/master/all-in-one/jaeger-all-in-one-template.yml | oc create -f -
```

- Create a route to access the Jaeger collector

```bash
oc expose service jaeger-collector --port=14268 -n tracing
```

- Specify next the url address of the Jaeger Collector to be used
- Get the route address

```bash
oc get route/jaeger-collector --template={{.spec.host}} -n tracing 
```
    
Add the following jaeger properties to the application.yml file with the route address of the collector

jaeger:
  protocol: HTTP
  sender: http://jaeger-collector-tracing.192.168.64.80.nip.io/api/traces

## Scale front

In order to show horizontal scaling, run then the oc command to scale the DeploymentConfig

```bash
oc scale --replicas=2 dc cloud-native-front
```

Then, verify that 2 pods are well running

```bash
oc get pods -l app=cloud-native-front
NAME                         READY     STATUS    RESTARTS   AGE
cloud-native-front-1-2pnbb   1/1       Running   0          3h
cloud-native-front-1-cc44g   1/1       Running   0          4h
```

Next, open 2 Web browsers or curl to check that you get a response from on of the round robin called pod

```bash
http -v http://cloud-native-front-cnd-demo.192.168.64.80.nip.io/ | grep 'id="_http_booster"'
<h2 id="_http_booster">Frontend at cloud-native-front-1-2pnbb</h2>
http -v http://cloud-native-front-cnd-demo.192.168.64.80.nip.io/ | grep 'id="_http_booster"'
<h2 id="_http_booster">Frontend at cloud-native-front-1-cc44g</h2>
```

## S2I Build using pipeline

- Create a `jenkinsfile` under the backend project

```bash
cat > jenkinsfile <<'EOL'
podTemplate(name: 'maven33', label: 'maven33', cloud: 'openshift', serviceAccount: 'jenkins', containers: [
    containerTemplate(name: 'jnlp',
        image: 'openshift/jenkins-slave-maven-centos7',
        workingDir: '/tmp',
        envVars: [
            envVar(key: 'MAVEN_MIRROR_URL',value: 'http://nexus-myproject.192.168.64.91.nip.io/nexus/content/groups/public/')
        ],
        cmd: '',
        args: '${computer.jnlpmac} ${computer.name}')
]){
  node("maven33") {
    checkout scm
    stage("Test") {
      sh "mvn test"
    }
    stage("Deploy") {
      sh "mvn  -Popenshift -DskipTests clean fabric8:deploy"
    }
  }
}
EOL
```

- Then delete the existing buildConfig

```bash
oc delete bc/cloud-native-backend
```

- Create a new build

```bash
oc new-build --strategy=pipeline https://github.com/snowdrop/cloud-native-backend.git
```

