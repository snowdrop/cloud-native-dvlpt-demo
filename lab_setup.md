# Teacher instructions

- Install jaeger within the `infra` project
```bash
oc project infra
process -f https://raw.githubusercontent.com/jaegertracing/jaeger-openshift/master/all-in-one/jaeger-all-in-one-template.yml | oc create -f -
deployment "jaeger" created
service "jaeger-query" created
service "jaeger-collector" created
service "jaeger-agent" created
service "zipkin" created
route "jaeger-query" created

oc expose service jaeger-collector --port=14268 -n infra  
```