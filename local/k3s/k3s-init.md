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


## restore from etcd snapshot

```bash	
k3s server \
  --cluster-reset \
  --cluster-reset-restore-path=/var/lib/rancher/k3s/server/db/snapshots/etcd-snapshot-cube03-1699182003
```