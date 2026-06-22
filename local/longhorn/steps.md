# label nodes

## allow scheduling on cube03
kubectl label nodes cube03 node.longhorn.io/create-default-disk=config
kubectl annotate nodes cube03 \
  'node.longhorn.io/default-disks-config=[{"path":"/data/raid/longhorn","allowScheduling":true}]'

## Reach the UI

We expose it using an ingress.

## list nodes that have longhorn disks

kubectl -n longhorn-system get nodes.longhorn.io

docs: https://longhorn.io/docs/1.9.1/nodes-and-volumes/nodes/default-disk-and-node-config/
