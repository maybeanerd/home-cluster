# system-upgrade-controller

Installs the [Rancher system-upgrade-controller](https://github.com/rancher/system-upgrade-controller)
and its `Plan` CRD.

This chart only installs the controller. The k3s upgrade Plans live in
`charts/k3s-upgrade-plans`.

## ArgoCD Application

Create this app **before** the Plans app so the CRD exists first.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: system-upgrade-controller
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/maybeanerd/home-cluster.git
    targetRevision: main
    path: charts/system-upgrade-controller
  destination:
    server: https://kubernetes.default.svc
    namespace: system-upgrade
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

Automated sync is safe here: updating the controller does not start a k3s
upgrade. The Plans app is the one that must stay manual.

## Updating the controller

The controller and CRD are vendored from the upstream release manifest:

- `templates/controller.yaml`
- `crds/plans.upgrade.cattle.io.yaml`

When bumping the controller:

1. Download the new `system-upgrade-controller.yaml` and `crd.yaml` from the
   upstream release.
2. Update both vendored files together.
3. Update `image.tag` in `values.yaml`.
4. Run `helm lint charts/system-upgrade-controller` and `helm template`.

Do not update only the image tag; the CRD and controller version must match.
