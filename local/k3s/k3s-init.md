# Setup k3s
Based on this https://docs.turingpi.com/docs/turing-pi2-kubernetes-installation
## Install on main node (cube01):
    
```bash
curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644 --disable servicelb --token SECRET --node-ip 10.0.0.61 --disable-cloud-controller --disable local-storage
```
## Install on other nodes (cube01, cube03, cube04):
    
```bash
curl -sfL https://get.k3s.io | K3S_URL=https://10.0.0.61:6443 K3S_TOKEN=SECRET sh -
```

# Restart nodes in attempt to revive cluster

## Kill all k3s related processes
```bash
/usr/local/bin/k3s-killall.sh
```

## main server/cube01:

```bash
curl -sfL https://get.k3s.io | K3S_TOKEN=SECRET sh -s - server \
    --cluster-init --disable=servicelb --write-kubeconfig-mode 644
```

To reset traefik, start with `--disable traefik` and then again without it once it's entirely gone. Also do this on all other nodes

## other servers:

```bash
curl -sfL https://get.k3s.io | K3S_TOKEN=SECRET sh -s - server \
    --server https://cube01:6443 --disable=servicelb --write-kubeconfig-mode 644
```

## agents:

```bash
curl -sfL https://get.k3s.io | K3S_TOKEN=SECRET sh -s - agent \
    --server https://cube01:6443
```
```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="agent --server https://cube01:6443 --token SECRET" sh -s -
```

### set up mnt storage for k3s containerd
https://github.com/k3s-io/k3s/issues/2068#issuecomment-1374672584

```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="agent --server https://cube01:6443 --token SECRET --kubelet-arg "root-dir=$KUBELET_DIR"" sh -s -
```

## assign roles
```bash
kubectl label nodes cube04 kubernetes.io/role=worker
```

## restore from etcd snapshot

```bash	
k3s server \
  --cluster-reset \
  --cluster-reset-restore-path=/var/lib/rancher/k3s/server/db/snapshots/etcd-snapshot-cube01-1706094002
```

### set up mnt storage for rpi with external drive on mnt/tardis

```bash
# uninstall
/usr/local/bin/k3s-agent-uninstall.sh
rm -r /mnt/tardis/k3s-containerd/run/
rm -r /mnt/tardis/k3s-containerd/var-lib-kubelet/
rm -r /mnt/tardis/k3s-containerd/var-lib/
rm -r /var/lib/rancher/

# set up
systemctl stop k3s-agent
systemctl stop containerd
/usr/local/bin/k3s-killall.sh
# create dirs
mkdir -p /mnt/tardis/k3s-containerd/run/
mkdir -p /mnt/tardis/k3s-containerd/var-lib-kubelet/
mkdir -p /mnt/tardis/k3s-containerd/var-lib/
# Move files to new location
mv /run/k3s/ /mnt/tardis/k3s-containerd/run/
mv /var/lib/kubelet/pods/ /mnt/tardis/k3s-containerd/var-lib-kubelet/
mv /var/lib/rancher/ /mnt/tardis/k3s-containerd/var-lib/
# Create symbolic links (adjusted)
ln -s /mnt/tardis/k3s-containerd/run/k3s/ /run/k3s
ln -s /mnt/tardis/k3s-containerd/var-lib-kubelet/pods/ /var/lib/kubelet/pods
ln -s /mnt/tardis/k3s-containerd/var-lib/rancher/ /var/lib/rancher
# Start K3s agent
systemctl start k3s-agent
```