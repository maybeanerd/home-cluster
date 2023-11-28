# Setup k3s
Based on this https://docs.turingpi.com/docs/turing-pi2-kubernetes-installation
## Install on main node (cube02):
    
```bash
curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644 --disable servicelb --token SECRET --node-ip 10.0.0.61 --disable-cloud-controller --disable local-storage
```
## Install on other nodes (cube02, cube03, cube04):
    
```bash
curl -sfL https://get.k3s.io | K3S_URL=https://10.0.0.61:6443 K3S_TOKEN=SECRET sh -
```

# Restart nodes in attempt to revive cluster

## main server/cube02:

```bash
curl -sfL https://get.k3s.io | K3S_TOKEN=SECRET sh -s - server \
    --cluster-init
```

To reset traefik, start with `--disable traefik` and then again without it once it's entirely gone. Also do this on all other nodes

## other servers:

```bash
curl -sfL https://get.k3s.io | K3S_TOKEN=SECRET sh -s - server \
    --server https://cube02:6443
```


## agents:

```bash
curl -sfL https://get.k3s.io | K3S_TOKEN=SECRET sh -s - agent \
    --server https://cube02:6443
```
```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="agent --server https://cube02:6443 --token SECRET" sh -s -
```

### set up mnt storage for k3s containerd
https://github.com/k3s-io/k3s/issues/2068#issuecomment-1374672584

```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="agent --server https://cube02:6443 --token SECRET --kubelet-arg "root-dir=$KUBELET_DIR"" sh -s -
```

## assign roles
```bash
kubectl label nodes cube04 kubernetes.io/role=worker
```

## restore from etcd snapshot

```bash	
k3s server \
  --cluster-reset \
  --cluster-reset-restore-path=/var/lib/rancher/k3s/server/db/snapshots/etcd-snapshot-cube03-1699182003
```