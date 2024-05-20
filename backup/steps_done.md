
# init
borg init ssh://uXXXXXX@uXXXXXX.your-storagebox.de:23/./cluster-backup --encryption=repokey

# initial backup
borg create --stats ssh://uXXXXXX@uXXXXXX.your-storagebox.de:23/./cluster-backup::2024_05_20_initial /var/lib/rancher/k3s/server/db/snapshots

### Directories to back up: 
- /var/lib/rancher/k3s/server/db/snapshots
- /data/raid/nas
- /data/raid/cubes
  - exclude: /data/raid/cubes/jellyfin-jellyfin-media-pvc-29eeb2d3-e6b4-43c0-8067-7152203615f0

### command to come out of this:
borg create --stats ssh://uXXXXXX@uXXXXXX.your-storagebox.de:23/./cluster-backup::2024_05_20_initial /var/lib/rancher/k3s/server/db/snapshots /data/raid/nas /data/raid/cubes --exclude /data/raid/cubes/jellyfin-jellyfin-media-pvc-29eeb2d3-e6b4-43c0-8067-7152203615f0

## Cron

TODO

https://community.hetzner.com/tutorials/install-and-configure-borgbackup#step-25---more-borg-commands-including-list-archives-restore-backups
