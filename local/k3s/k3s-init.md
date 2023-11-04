## main server/cube02:

```bash
curl -sfL https://get.k3s.io | K3S_TOKEN=SECRET sh -s - server \
    --cluster-init
```

To reset traefik, start with `--disable traefik` and then again without it once it's entirely gone. Also do this on all other nodes

## others:

```bash
curl -sfL https://get.k3s.io | K3S_TOKEN=SECRET sh -s - server \
    --server https://cube02:6443
```