# Post installation instructions

- Verify if APB pods are running. Restart deployments if failures exist
```bash
oc login https://46.4.81.220:8443 -u admin -p admin
oc get pods -n openshift-ansible-service-broker
```

- Install launcher
```bash
oc login https://46.4.81.220:8443 -u admin -p admin
oc project default
cd dvlpt-demo

./deploy_launcher_vm.sh -p my-launcher \
                     -i admin:admin \
                     -g gitUsername:gitPassword \
                     -c https://github.com/snowdrop/cloud-native-catalog.git
```