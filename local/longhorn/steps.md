# label nodes

## allow scheduling on cube03
kubectl label nodes cube03 node.longhorn.io/create-default-disk=config
kubectl annotate nodes cube03 \
  'node.longhorn.io/default-disks-config=[{"path":"/data/raid/longhorn","allowScheduling":true}]'

## Reach the UI

we expose it using nodePort, so if the pod is running on cube03, you can access it via:

http://cube03:32269


## list nodes that have longhorn disks

kubectl -n longhorn-system get nodes.longhorn.io


docs: https://longhorn.io/docs/1.9.1/nodes-and-volumes/nodes/default-disk-and-node-config/

TODO: ensure only cube03 has a disk configured, and it maps to the raid path