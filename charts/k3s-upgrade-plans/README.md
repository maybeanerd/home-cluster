# k3s-upgrade-plans

Defines the k3s server and agent upgrade Plans for
[system-upgrade-controller](https://github.com/rancher/system-upgrade-controller).

The version in `values.yaml` is the single source of truth. It is validated by
`.github/workflows/k3s-version-guard.yml`, which rejects any change that skips a
Kubernetes minor version.

## ArgoCD Application

Create the controller app first, then this one.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: k3s-upgrade-plans
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/maybeanerd/home-cluster.git
    targetRevision: main
    path: charts/k3s-upgrade-plans
  destination:
    server: https://kubernetes.default.svc
    namespace: system-upgrade
  syncPolicy:
    # Deliberately no automated sync. Merging a version bump only stages it;
    # a maintainer syncs this app during the maintenance window.
    syncOptions:
      - CreateNamespace=true
      - SkipDryRunOnMissingResource=true
```

## Upgrading k3s

1. Change `k3s.version` to the next patch or the next minor.
2. Open a PR. For a minor bump, add the `k3s-minor-upgrade` label.
3. Merge after the guard passes.
4. During the maintenance window, manually sync this app in ArgoCD.
5. The server Plan's `prepare` step takes an etcd snapshot and backs up the
   k3s binary before the server is upgraded.
6. The agent Plan waits for the server Plan, then upgrades the agents one at a
   time.
7. Verify, then record the snapshot name from the prepare logs.

Never set `channel`. The Plans use explicit `spec.version` values only.

## Cordon-only

Both Plans cordon the node but do not drain it. This is intentional: Longhorn is
single-node with one replica, and k3s restarts do not stop running containers.
