# Hands On Lab instructions for the Cloud Native Development

TODO - Add ToC (using gh-md-toc hands-on-lab.md)

## Requirements

1. Java - 1.8.x

2. Maven - 3.5.x

3. OpenShift oc client - [3.7.0](TODO)

## Objectives

- Discover OpenShift Cloud Platform
- Play with the different strategies to build a project on the platform
- Develop a real application (front, backend, database)
- Use Service Catalog to setup the database
- Enable Distributed Tracing
- Use Jenkins CI/CD and Pipeline

## Lab Scenario

### Access to the OpenShift platform

- Open the OpenShift Cluster within your browser and verify that you can log on to the machine using your user/pwd

Remark: Use the user/pwd and IP address assigned to you

- Get the token from the `command-line` screen using this URL `https://HETZNER_IP_ADDRESS:8443/console/command-line`
- Next, execute this command within your terminal to access to the cluster using your `oc` client tool

```bash
oc login https://HETZNER_IP_ADDRESS:8443 --token=3WiSqc3JyW5dkJ5izQvOBVFK-njXTTnpse8ruLiYaoQ
Logged into "https://HETZNER_IP_ADDRESS:8443" as "user1" using the token provided.

You have one project on this server: "project1"

Using project "project1".
```

- Check the status of the project

```bash
oc status
In project project1 on server https://HETZNER_IP_ADDRESS:8443

You have no services, deployment configs, or build configs.
Run 'oc new-app' to create an application.
```

- Familiarize your self with the `oc` client and look to the different commands

```bash
oc -h
```

### Generate Spring Boot Cloud Native Front project using the launcher

- Access to the launcher using the following URL `https://launchpad-my-launcher.HETZNER_IP_ADDRESS.nip.io`
- From the `launcher application` screen, click on `launch` button

![](image/launcher.png)

- Within the deployment type screen, click on the button `I will build and run locally`
- Next, select your mission : `Cloud Native Development - Demo Front`

![](image/missions.png)

- Choose `Spring Boot Runtime`
- Accept the `Project Info`
- Finally click on the button Select `Download as zip file`
- Create a folder where you will develop your code
mkdir -p cloud-native-demo
```bash
mkdir -p cloud-native-demo
cd cloud-native-demo
```
- Unzip the generated project within the `cloud-native-demo` folder
```bash
cd cloud-native-demo
mv ~/Downloads/booster-demo-front-spring-boot.zip .
unzip booster-demo-front-spring-boot.zip
cd booster-demo-front-spring-boot
```

- TODO - Add steps to code

- Build and launch spring-boot application locally to ensure the application is working
```bash
mvn clean spring-boot:run 
```

- Open the following URL `http://localhost:8090` within a screen of your web browser

- Deploy the application on the cloud platform using the `s2i` build process
```bash
mvn package fabric8:deploy -Popenshift
```

### Create a MySQL service instance using the Service Catalog

! Use the Web UI to create the Service and bind it. 
Alternatively, execute the following command using the definition file provided with the backend application (which is the subject of the next step) in order to create a serviceInstance for MySQL

```bash
oc create -f openshift/mysql_serviceinstance.yml
```

TODO - Add screenshots

### Use the launcher to generate a Cloud Native Demo - Backend zip
   
- Access to the launcher using the following URL `https://launchpad-my-launcher.HETZNER_IP_ADDRESS.nip.io`
- From the `launcher application` screen, click on `launch` button
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

TODO - Add screenshots

- Next, mount the secret of the MySQL service to the `Deploymentconfig` of the backend

```bash
oc env --from=secret/spring-boot-notes-mysql-binding dc/spring-boot-db-notes
```

TODO - Add screenshots

**NOTE**: If you create the service using the UI, then find the secret name of the DB and next click on the `add to application` button
to add the secret to the Deployment Config of your application

- Wait until the pod is recreated and then test the service

![](image/front-db.png)

```bash
#export BACKEND=$(oc get route/spring-boot-db-notes -o jsonpath='{.spec.host}' -n cnd-demo)
export BACKEND=$(minishift openshift service spring-boot-db-notes -n cnd-demo --url)
curl -k $BACKEND/api/notes 
curl -k -H "Content-Type: application/json" -X POST -d '{"title":"My first note","content":"Spring Boot is awesome!"}' $BACKEND/api/notes 
curl -k $BACKEND/api/notes/1
```
### Use Distributed Tracing to collect app traces

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
    
- Open the pom file and add the `Spring Boot JAeger starter` dependency
```xml
<!-- OpenTracing -->
<dependency>
	<groupId>me.snowdrop</groupId>
	<artifactId>opentracing-tracer-jaeger-spring-web-starter</artifactId>
	<version>0.0.1-SNAPSHOT</version>
</dependency>
```
    
- Add the following jaeger properties to the application.yml file with the route address of the collector

```yaml
jaeger:
  protocol: HTTP
  sender: http://jaeger-collector-tracing.HETZNER_IP_ADDRESS.nip.io/api/traces
```

- Redeploy your project / spring boot backend on the cloud platform
```bash
mvn clean package
oc start-build cloud-native-backend-s2i --from-dir=. --follow
```

- Check if the pod has been recreated using this oc command
```bash
oc get pods -w
```

- Open the 

### Scale front

- In order to showcase/demo horizontal scaling, then you will execute the following `oc` command to scale the DeploymentConfig
  of the `cloud-native-front application`

```bash
oc scale --replicas=2 dc cloud-native-front
```

- Then, verify that 2 pods are well running

```bash
oc get pods -l app=cloud-native-front
NAME                         READY     STATUS    RESTARTS   AGE
cloud-native-front-1-2pnbb   1/1       Running   0          3h
cloud-native-front-1-cc44g   1/1       Running   0          4h
```

- Next, open 2 Web browsers or curl to check that you get a response from on of the round robin called pod

```bash
http -v http://cloud-native-front-cnd-demo.192.168.64.80.nip.io/ | grep 'id="_http_booster"'
<h2 id="_http_booster">Frontend at cloud-native-front-1-2pnbb</h2>
http -v http://cloud-native-front-cnd-demo.192.168.64.80.nip.io/ | grep 'id="_http_booster"'
<h2 id="_http_booster">Frontend at cloud-native-front-1-cc44g</h2>
```

### S2I Build using pipeline

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

## Bonus

- Install Istio using ansible playbook

```bash
pushd $(mktemp -d)
echo "Git clone ansible project to install istio distro, project on openshift"
git clone https://github.com/istio/istio.git && cd istio/install/ansible

export ISTIO_VERSION=0.4.0 #or whatever version you prefer
export JSON='{"cluster_flavour": "ocp","istio": {"release_tag_name": "'"$ISTIO_VERSION"'", "auth": false}}'
echo "$JSON" > temp.json
ansible-playbook main.yml -e "@temp.json"
rm temp.json
```

