# Deployment

## Install cf-operator on Kubernetes.

```bash
IBMMasterMBP:cf-operator bjxzi$ helm install --name cf-operator --namespace cfo --set "global.operator.watchNamespace=kubecf" https://s3.amazonaws.com/cf-operators/helm-charts/cf-operator-v0.4.2%2B121.g0be7cf70.tgz
NAME:   cf-operator
LAST DEPLOYED: Mon Nov 11 14:21:26 2019
NAMESPACE: cfo
STATUS: DEPLOYED

RESOURCES:
==> v1/ClusterRole
NAME                    AGE
cf-operator             1s
cf-operator-quarks-job  1s

==> v1/ClusterRoleBinding
NAME                    AGE
cf-operator             1s
cf-operator-quarks-job  1s

==> v1/Deployment
NAME                    READY  UP-TO-DATE  AVAILABLE  AGE
cf-operator             0/1    1           0          1s
cf-operator-quarks-job  0/1    1           0          1s

==> v1/Namespace
NAME    STATUS  AGE
kubecf  Active  1s

==> v1/Pod(related)
NAME                                    READY  STATUS             RESTARTS  AGE
cf-operator-7745c59966-mvnt2            0/1    ContainerCreating  0         1s
cf-operator-quarks-job-84bbc4bb8-nm7ct  0/1    ContainerCreating  0         1s

==> v1/Role
NAME         AGE
cf-operator  1s
quarks-job   1s

==> v1/RoleBinding
NAME         AGE
cf-operator  1s
quarks-job   1s

==> v1/Service
NAME                 TYPE       CLUSTER-IP      EXTERNAL-IP  PORT(S)  AGE
cf-operator-webhook  ClusterIP  172.21.186.186  <none>       443/TCP  1s

==> v1/ServiceAccount
NAME                    SECRETS  AGE
cf-operator             1        1s
cf-operator-quarks-job  1        1s


NOTES:
Running the operator will install the following CRD´s:

- boshdeployments.fissile.cloudfoundry.org
- extendedjobs.fissile.cloudfoundry.org
- extendedsecrets.fissile.cloudfoundry.org
- extendedstatefulsets.fissile.cloudfoundry.org

You can always verify if the CRD´s are installed, by running:
 $ kubectl get crds

Interacting with the cf-operator pod

1. Check the cf-operator pod status
  kubectl -n cfo get pods

2. Tail the cf-operator pod logs
  export OPERATOR_POD=$(kubectl get pods -l name=cf-operator --namespace cfo --output name)
  kubectl -n cfo logs $OPERATOR_POD -f

3. Apply one of the BOSH deployment manifest examples
  kubectl -n kubecf apply -f docs/examples/bosh-deployment/boshdeployment-with-custom-variable.yaml

4. See the cf-operator in action!
  watch -c "kubectl -n kubecf get pods"

IBMMasterMBP:cf-operator bjxzi$ kubectl get pod -n cfo
NAME                          READY   STATUS    RESTARTS   AGE
cf-operator-9fcdd7f7c-8rd4c   1/1     Running   0          90s
IBMMasterMBP:cf-operator bjxzi$ kubectl logs cf-operator-9fcdd7f7c-8rd4c -n cfo
2019-11-06T06:29:54.849Z    INFO    internal/root.go:54    Using in-cluster kube config
2019-11-06T06:29:54.849Z    INFO    internal/root.go:58    Checking kube config
2019-11-06T06:29:54.914Z    INFO    cobra@v0.0.5/command.go:826    Starting cf-operator v0.4.2-dirty+85.gc6d71da5 with namespace kubecf
2019-11-06T06:29:54.914Z    INFO    cobra@v0.0.5/command.go:826    cf-operator docker image: cfcontainerization/cf-operator:v0.4.2-85.gc6d71da5
...
```

## Install Kube Cloud Foundry on cf-operator

### Set credentials

Fill ICD(IBM Cloud Database Service) and COS(Cloud Object Storage Service) credentials into `./202-icd-secrets.yaml` and `./204-cos-secrets.yaml`.

> **Notice:**
>
> We must set this port as integer manually in `deploy/201-icd-ops.yaml#L114`
>


## Set domain and ingress

Get ingress domain thou `ibmcloud ks cluster-get ${cluster_name} --json | jq -r '.ingressHostname'`
 and set values in `deploy/101-system-domain-secret.yaml` and `deploy/400-router-public-ingress.yaml` files.

### Install

Run `kubectl apply -R -f deploy/ --namespace kubecf`.

In order to install the files with correct ordering within a folder, a three digit prefix is added.
Files with a prefix require files with smaller prefixes to be installed before they are installed.


A rough guide for prefixing is the following:

- 1xx - Base kubecf
- 2xx - Ops resources for IBM Cloud Services
- 300 - BoshDeployment resource
- 400 - other resources

## Deploy an app on Kubernetes cluster using cf-push

```bash
# Get admin password
admin_password=$(kubectl get secret kubecf.var-cf-admin-password --namespace kubecf -ojson | jq -r '.data.password' | base64 --decode)
cf api https://api.${iks_cluster_domain}
# Logi
cf login -u admin -p ${admin_password}
cf create-org quarks 
cf target -o quarks 
cf create-space dev 
cf target -s dev 
# Push app
git clone https://github.com/rohitsakala/cf-hello-worlds.git
cd cf-hello-worlds/python-flask
cf push app1
```

## Curl the app to check if it is deployed correctly

```bash
curl https://app1.${iks_cluster_domain}
```