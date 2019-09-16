# cf-sanity
Build cf deployment manifest for cf-operator

## With ICD

User need to fill in the variables in [implicit-secrets](deploy/implicit-secrets.yaml)

```shell
kubectl apply -f ./ops --namespace scf
```

## Deploy scf v3
```shell
kctl apply -R -f ./deploy/ --namespace scf
```