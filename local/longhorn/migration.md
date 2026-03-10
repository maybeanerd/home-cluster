# Migrate a namespace from nfs-client to default (longhorn)

## Install pvmigrate
https://github.com/replicatedhq/pvmigrate

```bash
curl -sLO https://github.com/replicatedhq/pvmigrate/releases/download/v0.12.2/pvmigrate_linux_arm64.tar.gz
tar xzf pvmigrate_linux_arm64.tar.gz
sudo mv pvmigrate /usr/local/bin/
```

## preflight validation
```bash
KUBECONFIG=/etc/rancher/k3s/k3s.yaml pvmigrate --source-sc "nfs-client" --dest-sc "longhorn" --rsync-image "alpine:latest" --verbose-copy --preflight-validation-only --namespace "<namespace>"
```

## migrate
```bash
KUBECONFIG=/etc/rancher/k3s/k3s.yaml pvmigrate --source-sc "nfs-client" --dest-sc "longhorn" --rsync-image "alpine:latest" --verbose-copy --namespace "<namespace>"
```