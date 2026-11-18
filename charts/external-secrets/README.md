# external-secrets

Runs the External Secrets Operator and keeps the atcr.io registry login in the
`atcr-pull-credentials` Secret in this namespace, exposed to apps through the
`atcr` ClusterSecretStore.

To give another namespace the pull secret, copy
`charts/knot/templates/external-secret.yaml` into that chart and add:

```yaml
imagePullSecret:
  enabled: true
  storeName: atcr
  credentialsSecret: atcr-pull-credentials
  name: imagepullsecret
```
