
# init
borg init ssh://uXXXXXX@uXXXXXX.your-storagebox.de:23/./cluster-backup --encryption=repokey

# initial backup
borg create --stats ssh://uXXXXXX@uXXXXXX.your-storagebox.de:23/./cluster-backup::2024_05_20_initial /var/lib/rancher/k3s/server/db/snapshots

Next step: https://community.hetzner.com/tutorials/install-and-configure-borgbackup#step-25---more-borg-commands-including-list-archives-restore-backups