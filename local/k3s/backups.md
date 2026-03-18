We should be able to upload backups of our etcd to our s3 bucket directly using k3s

    Edit your K3s config:
    bash

    sudo nano /etc/rancher/k3s/config.yaml

    Add these lines to enable scheduled backups to S3:
    yaml

    etcd-s3: true
    etcd-s3-endpoint: "://your-provider.com"
    etcd-s3-bucket: "your-bucket-name"
    etcd-s3-access-key: "YOUR_ACCESS_KEY"
    etcd-s3-secret-key: "YOUR_SECRET_KEY"
    etcd-snapshot-schedule-cron: "0 */12 * * *"  # Runs every 12 hours
    etcd-snapshot-retention: 10                  # Keep last 10 local
    etcd-s3-retention: 10                        # Keep last 10 in S3
