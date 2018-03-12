# Post installation instructions

- IP addresses of the hetzner machine
```bash
Fast: 195.201.87.126
Slow: 46.4.81.220
```

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
                     -c https://github.com/snowdrop/cloud-native-catalog.git \
                     -b student
```

- Jenkins and pipeline

  - Grant access for the Jenkins pipeline to the namespace of the project

  ```bash
  oc adm policy add-cluster-role-to-user edit system:serviceaccount:infra:jenkins -n project99
  ```
    
  - Edit `openshift-sync-plugin` toi add the namespace of the new project and save jenkons configuration

- Generate PDF
```bash
markdown-pdf HANDS_ON_LAB.md 
```

