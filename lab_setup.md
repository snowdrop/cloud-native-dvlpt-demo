# Teacher instructions

- Install jaeger within the `infra` project
```bash
oc project infra
process -f https://raw.githubusercontent.com/jaegertracing/jaeger-openshift/master/all-in-one/jaeger-all-in-one-template.yml | oc create -f -
oc expose service jaeger-collector --port=14268 -n infra  
```