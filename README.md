# cf-sanity
Build cf deployment manifest for cf-operator

## With ICD

User need to fill in the variables in [implicit-secrets](deploy/102-external-db-secrets.yaml)


## Deploy scf v3
```shell
kctl apply -R -f ./deploy/ --namespace scf
```