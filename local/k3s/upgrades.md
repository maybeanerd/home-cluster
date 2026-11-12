# k3s upgrades

Status: **draft plan** for [#1642](https://github.com/maybeanerd/home-cluster/issues/1642).

## Problem

Updating k3s is currently manual and fragile:

- the install script has to be re-run with the same flags/env vars every time,
- the version is pinned in shell commands rather than in Git,
- it is easy to accidentally jump Kubernetes minors, which k3s explicitly does not support,
- there is no standard pre-upgrade snapshot/rollback procedure.

The k3s docs recommend [system-upgrade-controller](https://docs.k3s.io/upgrades/automated) for this. The docs also warn that SUC itself **does not protect against skipping minor versions**.

## Goals

- Pin the k3s version in Git and upgrade it through GitOps.
- Use `system-upgrade-controller` with explicit versions, never release channels.
- Never skip a Kubernetes minor version.
- Upgrade the server before the agents.
- Make node configuration reproducible (`/etc/rancher/k3s/config.yaml`, not ad-hoc env vars).
- Have a documented, tested snapshot/rollback procedure.

## Non-goals

- Automatic minor upgrades.
- OS/kernel upgrades.
- Changing Longhorn replica counts or topology.
- Secrets management (tracked separately in #1651).

## Assumptions

- k3s on Ubuntu.
- Three nodes: one server (master) and two agents.
- etcd runs on the single server (single etcd member).
- The repo currently documents `v1.31.5+k3s1`; the live version still needs to be confirmed.
- The nodes are currently configured through install-script env vars; there is no `/etc/rancher/k3s/config.yaml` yet.
- Longhorn is effectively single-node with **1 replica** (`charts/longhorn/values.yaml`) and is expected to stay that way for now.
- ArgoCD manages the charts; Applications are currently created manually.
- The planning environment has no cluster access.

## Current upstream versions (as of 2026-11-06)

- Stable k3s: **v1.37.2+k3s1**
- Latest patches:
  - 1.31: v1.31.14+k3s1
  - 1.32: v1.32.13+k3s1
  - 1.33: v1.33.13+k3s2
  - 1.34: v1.34.13+k3s1
  - 1.35: v1.35.10+k3s1
  - 1.36: v1.36.6+k3s1
  - 1.37: v1.37.2+k3s1
- Kubernetes supports the latest three minors: 1.35, 1.36, 1.37.

## Upgrade path (if the cluster is still on 1.31.5)

| Step | From | To | Type |
|---|---|---|---|
| 0 | v1.31.5+k3s1 | v1.31.14+k3s1 | patch warm-up |
| 1 | v1.31.14+k3s1 | v1.32.13+k3s1 | minor |
| 2 | v1.32.13+k3s1 | v1.33.13+k3s2 | minor |
| 3 | v1.33.13+k3s2 | v1.34.13+k3s1 | minor |
| 4 | v1.34.13+k3s1 | v1.35.10+k3s1 | minor |
| 5 | v1.35.10+k3s1 | v1.36.6+k3s1 | minor |
| 6 | v1.36.6+k3s1 | v1.37.2+k3s1 | minor |

If the cluster is already newer, drop the earlier rows. The mechanism is unchanged.

## Design

### Two charts, two apps

Split into two charts so controller updates can autosync independently of k3s version changes:

- `charts/system-upgrade-controller` — pinned SUC controller + CRD. Its Argo app may autosync.
- `charts/k3s-upgrade-plans` — the `k3s.version` value and the server/agent Plans. Its Argo app has automated sync disabled.

Create the controller app first so the CRD exists, then the Plans app. Set `SkipDryRunOnMissingResource=true` on the Plans app to avoid dry-run failures on a fresh cluster.

Both Plans render `spec.version` from the same value in `charts/k3s-upgrade-plans/values.yaml`.

The server Plan:

```yaml
apiVersion: upgrade.cattle.io/v1
kind: Plan
metadata:
  name: k3s-server
  namespace: system-upgrade
spec:
  concurrency: 1
  cordon: true
  exclusive: true
  jobActiveDeadlineSecs: 1800
  postCompleteDelay: 1m
  version: v1.31.5+k3s1
  nodeSelector:
    matchExpressions:
      - key: node-role.kubernetes.io/control-plane
        operator: Exists
  serviceAccountName: system-upgrade
  tolerations:
    - key: node-role.kubernetes.io/control-plane
      operator: Exists
      effect: NoSchedule
  upgrade:
    image: rancher/k3s-upgrade
```

The agent Plan is the same, except:

- selector is `node-role.kubernetes.io/control-plane DoesNotExist`,
- `prepare` waits for the server Plan to finish:

```yaml
  prepare:
    image: rancher/k3s-upgrade
    args:
      - prepare
      - k3s-server
```

`rancher/k3s-upgrade` without a tag is intentional: SUC uses the target version as the image tag, so the upgrade image always matches `spec.version`.

### No `channel`, ever

Plans use `spec.version` only. A CI check rejects any Plan containing `spec.channel`, and rejects `stable`, `latest`, or a minor-only channel.

### Cordon only, no drain

Longhorn is effectively single-node (one Longhorn node, 1 replica) and is expected to stay that way for now. Draining a node with the last replica would either block or make the volume unavailable. CNPG may also have single-instance clusters.

K3s restart does not stop running containers, so cordon-only is the default policy:

```yaml
  cordon: true
  # no drain
```

This is not a temporary workaround; it is the intended policy for this cluster. Revisit only if the Longhorn topology changes (multiple Longhorn nodes / replicas ≥2) and the stateful workloads have been reviewed.

### Requirement: migrate node config before any upgrade

This is a **hard prerequisite** for the first version change (Phase 3). No k3s version bump is synced to ArgoCD until all three nodes have migrated to `/etc/rancher/k3s/config.yaml` and survived a restart.

SUC would still work with env-var-configured nodes, because it only replaces the binary and restarts the existing service. We migrate anyway so a reinstall/reboot does not depend on remembering the install-script env vars.

#### Acceptance criteria

- [ ] `/etc/rancher/k3s/config.yaml` exists on all three nodes, mode `0600`.
- [ ] The systemd unit no longer carries runtime flags; the env file is empty or contains only a secret (`K3S_TOKEN`).
- [ ] `force-new-cluster=true` is gone.
- [ ] Each node is `Ready` after `systemctl restart`.
- [ ] Workloads on the node are healthy.
- [ ] At least one agent has survived a full reboot.
- [ ] The old unit/env files are backed up outside `/etc/rancher/k3s`.

#### 0. Prepare

- Pick a window for the server step (brief API outage).
- On each node, back up the current unit and env file:

  ```bash
  sudo mkdir -p /root/k3s-config-backup
  sudo cp -a /etc/systemd/system/k3s.service /root/k3s-config-backup/  # or k3s-agent.service
  sudo cp -a /etc/systemd/system/k3s.service.env /root/k3s-config-backup/
  sudo cp -a /etc/rancher/k3s /root/k3s-config-backup/rancher-k3s
  ```

- Record the current version:

  ```bash
  k3s --version
  ```

#### 1. Capture the current configuration

On each node:

```bash
systemctl cat k3s              # or k3s-agent
sudo cat /etc/systemd/system/k3s.service.env
sudo ps -ef | grep -E '[k]3s (server|agent)'
sudo ls -la /etc/rancher/k3s/
```

Also check `/etc/default/k3s` and any `K3S_*` variables in the unit's `Environment=` / `EnvironmentFile=` entries.

#### 2. Translate env vars to config keys

K3s config file keys are the long flag names without `--`. Common mappings:

| Env var | Config key | Notes |
|---|---|---|
| `K3S_TOKEN` | `token` | Secret; keep file `0600` |
| `K3S_URL` | `server` | Agent only |
| `K3S_NODE_IP` | `node-ip` | |
| `K3S_NODE_NAME` | `node-name` | |
| `K3S_DATA_DIR` | `data-dir` | Preserve if moved to another disk |
| `K3S_DISABLE` | `disable` | List |
| `K3S_CLUSTER_INIT` | `cluster-init` | Server bootstrap |
| `K3S_WRITE_KUBECONFIG_MODE` | `write-kubeconfig-mode` | Quote as string |
| `K3S_KUBELET_ARG` | `kubelet-arg` | List |
| `K3S_ETCD_ARG` | `etcd-arg` | List; drop `force-new-cluster=true` |
| `K3S_FLANNEL_IFACE` | `flannel-iface` | |
| `K3S_ETCD_S3` | `etcd-s3` | |
| `K3S_ETCD_S3_CONFIG_SECRET` | `etcd-s3-config-secret` | |
| `K3S_ETCD_SNAPSHOT_SCHEDULE_CRON` | `etcd-snapshot-schedule-cron` | Quote cron |
| `K3S_KUBE_APISERVER_ARG` | `kube-apiserver-arg` | List |
| `K3S_KUBE_CONTROLLER_MANAGER_ARG` | `kube-controller-manager-arg` | List |
| `K3S_KUBE_PROXY_ARG` | `kube-proxy-arg` | List |
| `K3S_RESOLV_CONF` | `resolv-conf` | |
| `K3S_SELINUX` | `selinux` | |

If a value is a repeatable flag, use a YAML list.

#### 3. Write config.yaml

```bash
sudo install -d -m 700 /etc/rancher/k3s
sudo install -m 600 /dev/null /etc/rancher/k3s/config.yaml
sudo editor /etc/rancher/k3s/config.yaml
```

Server example:

```yaml
# /etc/rancher/k3s/config.yaml (server)
write-kubeconfig-mode: "0644"
disable:
  - servicelb
  - traefik
  - local-storage
disable-cloud-controller: true
node-ip: 192.168.1.102
etcd-s3: true
etcd-s3-config-secret: k3s-etcd-s3-config
etcd-snapshot-schedule-cron: "0 */12 * * *"
token: <secret>
```

Agent example:

```yaml
# /etc/rancher/k3s/config.yaml (agent)
server: https://cube01:6443
token: <secret>
node-ip: 192.168.1.x
```

#### 4. Regenerate the systemd unit without flags

Use the **current** version, not the target version. This step must not upgrade k3s.

Server:

```bash
CURRENT="$(k3s --version | awk '{print $3}')"
curl -sfL https://get.k3s.io | \
  INSTALL_K3S_VERSION="$CURRENT" \
  INSTALL_K3S_SKIP_START=true \
  INSTALL_K3S_EXEC=server \
  sh -s -
sudo systemctl daemon-reload
sudo systemctl restart k3s
```

Agent:

```bash
CURRENT="$(k3s --version | awk '{print $3}')"
curl -sfL https://get.k3s.io | \
  INSTALL_K3S_VERSION="$CURRENT" \
  INSTALL_K3S_SKIP_START=true \
  INSTALL_K3S_EXEC=agent \
  sh -s -
sudo systemctl daemon-reload
sudo systemctl restart k3s-agent
```

If the generated env file still contains `K3S_URL` / `K3S_TOKEN`, either leave it (it is no longer manually re-supplied) or remove it after verifying `config.yaml` is being read. Do not lose the token.

#### 5. Verify

```bash
systemctl status k3s
journalctl -u k3s -n 100 --no-pager
kubectl get nodes -o wide
kubectl get pods -A --field-selector=status.phase!=Running
```

Check the node is `Ready`, the version is unchanged, and workloads are healthy.

#### 6. Order

1. Agent 1
2. Agent 2
3. Server (brief API outage)
4. Reboot one agent and verify it rejoins

#### 7. Rollback

If a node fails to start:

1. Stop k3s.
2. Restore the backed-up unit/env.
3. Move `config.yaml` aside so the old flags/env are the only config.
4. `systemctl daemon-reload`
5. Start k3s and verify.

#### Watch for

- `force-new-cluster=true` in `K3S_ETCD_ARG` or `ExecStart` — remove it.
- `K3S_TOKEN` / `K3S_TOKEN_FILE` — don't lose it.
- `K3S_DATA_DIR` — preserve external disk paths.
- `K3S_KUBELET_ARG=root-dir=...` — preserve list syntax.
- `K3S_ETCD_ARG` tuning — preserve everything except `force-new-cluster`.
- `K3S_NODE_IP` / `K3S_NODE_NAME` / `K3S_FLANNEL_IFACE` — networking; a mistake can make the node unreachable.
- `K3S_DISABLE` — servicelb/traefik/local-storage.
- `K3S_WRITE_KUBECONFIG_MODE` — keep `"0644"` quoted.
- Any `--flag` in `ExecStart` that is not in the env file.
- `/etc/default/k3s` and extra `EnvironmentFile=` entries.

### One minor at a time, enforced in CI

A GitHub Action compares the version in `charts/k3s-upgrade-plans/values.yaml` on the PR base and head:

- reject major changes,
- reject downgrades,
- reject `newMinor - oldMinor > 1`,
- require a `k3s-minor-upgrade` label for minor bumps.

Failure messages should name the next allowed minor, e.g. “1.31.5 → 1.37.2 skips 5 minors; next allowed step is 1.32.x.”

Both Plans render from the same value, so they cannot drift. Branch protection ensures the CI guard must pass before merge. The controller/CRD app may autosync; the Plans app is configured **without automated sync**, so merging a version bump does not start an upgrade; a maintainer manually syncs the app during the maintenance window. Because automated sync is off on the Plans app, ArgoCD will not self-heal manual Plan edits either; the CI guard, branch protection, and RBAC are the protections there.

### Automation and deployment flow

Renovate may open PRs for patch, minor, and major k3s releases. All k3s PRs are explicitly non-automerge:

```json
{
  "matchPackageNames": ["k3s-io/k3s"],
  "labels": ["k3s", "do-not-automerge"],
  "automerge": false,
  "platformAutomerge": false
}
```

The CI guard decides whether a PR is mergeable:

- patch within the current minor: mergeable,
- exactly one minor ahead: mergeable with the `k3s-minor-upgrade` label,
- more than one minor ahead: blocked. Renovate may still open it as a signal; it is not a merge candidate until the intermediate minors are done.

Renovate proposes the newest available version. If that skips one or more minors, the guard blocks the PR. We deliberately do not pin `allowedVersions` to the next minor: the blocked latest-version PR is useful visibility, and the next-minor PR is created manually. If the blocked PR becomes noisy, close it; it is not part of the upgrade path.

Deployment flow:

1. Renovate/manual PR updates `k3s.version`.
2. CI guard validates the step.
3. Merge to `main`.
4. ArgoCD sees the change but does **not** auto-sync the Plans app.
5. During the maintenance window, manually sync the app.
6. The server Plan's prepare step takes an etcd snapshot and backs up the k3s binary.
7. SUC upgrades the server, then the agent Plan runs.
8. Verify and record the result, including the snapshot name from the prepare logs.

### Snapshots and rollback

`k3s-upgrade` only replaces the binary and restarts k3s. It does **not** take an etcd snapshot.

The PR cannot run commands on the servers; it only changes Git. The snapshot must happen after the manual ArgoCD sync, immediately before SUC upgrades the server. The chosen mechanism is A; B is the fallback if A fails validation.

**A. Automatic prepare step on the server Plan (chosen)**

Add a `prepare` init container to the server Plan. SUC already runs the upgrade job with `hostPID`, `hostNetwork`, host root mounted at `/host`, and privileged by default. The prepare step can therefore run:

```sh
TARGET="$(echo "$SYSTEM_UPGRADE_PLAN_LATEST_VERSION" | tr '+' '-')"
NAME="pre-upgrade-${TARGET}-$(date -u +%Y%m%dT%H%M%SZ)"
chroot /host /usr/local/bin/k3s etcd-snapshot save --name "$NAME"
cp -a /host/usr/local/bin/k3s "/host/usr/local/bin/k3s.pre-${TARGET}"
```

This runs before cordon/upgrade, and the upgrade does not proceed if the snapshot or binary backup fails. The snapshot name is in the prepare container logs; record it in the upgrade issue/PR comment after the sync.

**B. Manual pre-sync step (fallback)**

If the privileged prepare cannot be made to work, run the same commands over SSH on the server before manually syncing the ArgoCD app. The PR still only contains the version bump; the snapshot is a runbook step, not a PR step.

Phase 3 must validate A on one patch upgrade before relying on it. If `chroot` or the snapshot command fails inside the prepare container, fall back to B.

Rollback is restore, not downgrade:

- stop k3s,
- restore the pre-upgrade etcd snapshot,
- restore the previous k3s binary,
- start k3s and verify.

SUC refuses downgrades, so changing the Plan to an older version is not a rollback path.

## Repo changes

- `charts/system-upgrade-controller/`
  - `Chart.yaml`, `values.yaml`, `values.schema.json`
  - SUC CRD + controller manifests (pinned)
  - `README.md` with the suggested ArgoCD Application spec (autosync allowed)
- `charts/k3s-upgrade-plans/`
  - `Chart.yaml`, `values.yaml`, `values.schema.json`
  - `templates/plans.yaml`
  - `README.md` with the suggested ArgoCD Application spec (autosync disabled, `SkipDryRunOnMissingResource=true`)
- `local/k3s/upgrades.md` — this runbook
- `local/k3s/config/server.example.yaml` and `agent.example.yaml`
- `scripts/check-k3s-version.py`
- `.github/workflows/k3s-version-guard.yml`
- `renovate.json` — regex manager + explicit no-automerge rule for k3s
- update `local/k3s/k3s-init.md` and `local/k3s/backups.md`

## Phases

- [ ] **Phase 0 — Discovery**
  - Collect `kubectl get nodes -o wide`.
  - Check `/etc/rancher/k3s/config.yaml` and systemd units on all three nodes.
  - Check whether `force-new-cluster=true` is still in the server config/unit.
  - Verify the S3 etcd snapshot is current and restorable.
  - Check Longhorn volume health and CNPG cluster instance counts.

- [ ] **Phase 1 — Config hygiene**
  - Capture the current unit/env/process args on each node.
  - Move server/agent flags into `/etc/rancher/k3s/config.yaml` (mode `0600`).
  - Remove `force-new-cluster=true` from steady-state config.
  - Regenerate the systemd unit without runtime flags.
  - Migrate one agent, verify, then the other, then the server.
  - Verify a reboot/restart still joins correctly.
  - Add example configs to the repo (no tokens).

- [ ] **Phase 2 — Install SUC**
  - Add both charts.
  - Create the controller app first, then the Plans app.
  - Set the Plan version to the currently running version (no-op).
  - Verify Plans report complete and no jobs run.

- [ ] **Phase 3 — Patch warm-up**
  - Upgrade within the current minor (e.g. 1.31.5 → 1.31.14).
  - Validate the automatic snapshot prepare step, cordon/uncordon, job logs, and rollback readiness.

- [ ] **Phase 4 — Minor upgrades**
  - One minor per PR and maintenance window.
  - Server first, then agents.
  - Verify Longhorn, CNPG, ArgoCD, ingress, and the status page between steps.

- [ ] **Phase 5 — Steady state**
  - Renovate opens patch/minor/major PRs, all explicitly non-automerge.
  - The CI guard only allows a one-minor step; larger PRs stay blocked.
  - Minor upgrades are merged and then manually synced in ArgoCD during a maintenance window.
  - Review supported minors before each Kubernetes release cycle.

## Runbook (per upgrade)

### Pre-flight

- [ ] All nodes `Ready` and on the same version.
- [ ] `kubectl get --raw='/readyz?verbose'` is healthy.
- [ ] Longhorn volumes healthy; no degraded/rebuilding volumes.
- [ ] CNPG clusters healthy.
- [ ] `kubectl -n system-upgrade get plans` shows no in-progress plan.
- [ ] S3 etcd snapshot config is working; the last scheduled snapshot exists.
- [ ] Fallback only: if A is unavailable, do the manual pre-sync snapshot/binary backup before syncing ArgoCD.
- [ ] Maintenance window announced.

### During

- [ ] Manually sync the ArgoCD app for the Plans (automated sync is disabled).
- [ ] Confirm the server Plan's prepare step created the etcd snapshot and binary backup.
- [ ] Watch `kubectl -n system-upgrade get plans,jobs,pods`.
- [ ] Watch `kubectl get nodes -o wide`.
- [ ] Confirm the server Plan completes before agents start.
- [ ] Expect a brief API outage during the single-server restart.

### After

- [ ] All nodes on the target version.
- [ ] `kubectl get --raw='/readyz?verbose'` healthy.
- [ ] Longhorn volumes healthy.
- [ ] CNPG clusters healthy.
- [ ] ArgoCD applications synced/healthy.
- [ ] Ingress and status page reachable.
- [ ] Record the snapshot name from the prepare logs in the upgrade issue/PR comment.

### If it fails

- Do not start the next minor.
- Inspect the failed Job logs and k3s service logs on the node.
- The node stays cordoned after a failed upgrade.
- If the server cannot start, restore the pre-upgrade snapshot and binary.
- If an agent cannot start, restore the previous binary or reinstall k3s, then retry.
- Only uncordon after the node is healthy.

## Decisions

- Cordon-only, no drain. This is the intended policy for the single-node Longhorn setup.
- Renovate may open patch/minor/major PRs, but all k3s PRs are explicitly non-automerge.
- Renovate proposes the latest version; the CI guard blocks anything that skips a minor, and the next-minor PR is created manually.
- The Plans app is manually created in ArgoCD and manually synced; automated sync is disabled.
- Two charts/apps: `system-upgrade-controller` (controller + CRD, autosync allowed) and `k3s-upgrade-plans` (Plans, manual sync).
- Config migration from env vars to `/etc/rancher/k3s/config.yaml` is Phase 1.
- Snapshot mechanism: automatic `prepare` step on the server Plan (A), with manual pre-sync (B) as fallback.

## Open questions

1. **Current version:** what does `kubectl get nodes -o wide` show? Is it still `v1.31.5+k3s1`?
2. **Target:** catch up to v1.37.2, or stop at v1.35.10 (oldest supported) first?
3. **Cadence:** one minor per Sunday 02:00–04:00 Europe/Berlin window?
4. **Config:** please paste `systemctl cat k3s` / `k3s-agent` and the matching `.service.env` from each node so we can translate them accurately.

## References

- k3s automated upgrades: https://docs.k3s.io/upgrades/automated
- k3s manual upgrades / release channels: https://docs.k3s.io/upgrades/manual
- Kubernetes version skew: https://kubernetes.io/releases/version-skew-policy/
- system-upgrade-controller Plan API: https://github.com/rancher/system-upgrade-controller/blob/master/doc/plan.md
