# label nodes

## allow scheduling on cube03
kubectl label nodes cube03 node.longhorn.io/create-default-disk=true
kubectl annotate nodes cube03 \
  'node.longhorn.io/default-disks-config=[{"path":"/data/raid/longhorn","allowScheduling":true}]'
