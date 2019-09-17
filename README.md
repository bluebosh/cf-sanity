# cf-sanity
Build kube resources manifest for cf-operator

## With ICD

User needs to fill in the variables in [implicit-secrets](deploy/102-external-db-secrets.yaml)


## Deploy scf v3
```shell
kctl apply -R -f ./deploy/ --namespace scf
```