
# init
borg init ssh://uXXXXXX@uXXXXXX.your-storagebox.de:23/./cluster-backup --encryption=repokey

# initial backup
borg create --stats --progress ssh://uXXXXXX@uXXXXXX.your-storagebox.de:23/./cluster-backup::2024_05_20_initial /var/lib/rancher/k3s/server/db/snapshots

### Directories to back up: 
- /var/lib/rancher/k3s/server/db/snapshots
- /data/raid/nas
- /data/raid/cubes
  - exclude: /data/raid/cubes/jellyfin-jellyfin-media-pvc-29eeb2d3-e6b4-43c0-8067-7152203615f0

### command to come out of this:
borg create --stats --progress ssh://uXXXXXX@uXXXXXX.your-storagebox.de:23/./cluster-backup::2024_05_20_initial /var/lib/rancher/k3s/server/db/snapshots /data/raid/nas /data/raid/cubes --exclude /data/raid/cubes/jellyfin-jellyfin-media-pvc-29eeb2d3-e6b4-43c0-8067-7152203615f0

## Cron

TODO

https://community.hetzner.com/tutorials/install-and-configure-borgbackup#step-25---more-borg-commands-including-list-archives-restore-backups


### First full backup steps
- k3s etcd snapshots, done
- nas
  - its about 700GB
  - do we need everything?
- cubes
  - everything except jellyfin media
  - clean up immich first? might want to do a clean setup for that
  - how will DBs deal with this. rather just backups of snapshots/db backups?


## testing

### back up k3s snapshots
borg create --stats --progress ssh://uXXXXXX@uXXXXXX.your-storagebox.de:23/./cluster-backup::2024_07_21_k3s_initial /var/lib/rancher/k3s/server/db/snapshots

### manually back up vaultwarden
copy to tmp folder

### borg backup of vaultwarden
borg create --stats --progress ssh://uXXXXXX@uXXXXXX.your-storagebox.de:23/./cluster-backup::2024_07_21_VW_initial /data/raid/cubes/vaultwarden-vaultwarden-pvc-37c8a00f-c75d-44cc-a09d-fc6a6ff76bda
### outcome
both seemed to work perfectly!