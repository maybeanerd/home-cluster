We should be able to upload backups of our etcd to our s3 bucket directly using k3s

## Create Secret

kubectl create secret generic k3s-etcd-s3-config \
  --namespace kube-system \
  --from-literal=etcd-s3-endpoint="fsn1.your-objectstorage.com" \
  --from-literal=etcd-s3-access-key="<YOUR_ACCESS_KEY>" \
  --from-literal=etcd-s3-secret-key="<YOUR_SECRET_KEY>" \
  --from-literal=etcd-s3-bucket="<YOUR_BUCKET_NAME>" \
  --from-literal=etcd-s3-region="fsn1" \
  --from-literal=etcd-s3-folder="k3s-etcd-backups"

## Use secret to upload backups to s3
  
sudo nano /etc/rancher/k3s/config.yaml

etcd-s3: true
etcd-s3-config-secret: "k3s-etcd-s3-config"
etcd-snapshot-schedule-cron: "0 */12 * * *"
