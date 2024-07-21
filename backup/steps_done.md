
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
#### K3S
borg create --stats --progress ssh://uXXXXXX@uXXXXXX.your-storagebox.de:23/./cluster-backup::2024_07_21_initial_k3s /var/lib/rancher/k3s/server/db/snapshots

#### NAS
This is 200GB+ of files, figure out if we really want all of this backed up remotely
borg create --stats --progress ssh://uXXXXXX@uXXXXXX.your-storagebox.de:23/./cluster-backup::2024_07_21_initial_nas /data/raid/nas

### Cubes (kubernetes persistent volumes)
borg create --stats --progress ssh://uXXXXXX@uXXXXXX.your-storagebox.de:23/./cluster-backup::2024_07_21_initial_cubes /data/raid/cubes --exclude /data/raid/cubes/jellyfin-jellyfin-media-pvc-29eeb2d3-e6b4-43c0-8067-7152203615f0 --exclude /data/raid/cubes/immich-immich-machine-learning-cache-pvc-e7659a22-496f-4cab-a554-3a4fdf2677d6 --exclude /data/raid/cubes/paperless-paperless-consume-pvc-1eebc996-fa85-4438-8173-1bb29399e34c --exclude /data/raid/cubes/kube-system-traefik-pvc-aeb1e86f-9595-4ee9-8f93-33b33d7269b4 --exclude /data/raid/cubes/audiobookshelf-audiobookshelf-audiobooks-pvc-fd18bca7-a973-451d-98f8-1de0de0a440d --exclude /data/raid/cubes/audiobookshelf-audiobookshelf-podcasts-pvc-596128f3-5a0d-402a-b08f-699454e0b4dc

for testing, add `--dry-run`

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


### Immich test
DB

borg create --stats --progress ssh://uXXXXXX@uXXXXXX.your-storagebox.de:23/./cluster-backup::2024_07_21_Immich_DB_initial /data/raid/cubes/immich-data-immich-postgresql-0-pvc-b9bea140-dd7c-4181-91d3-05b1dcd62dd2

Images

borg create --stats --progress ssh://uXXXXXX@uXXXXXX.your-storagebox.de:23/./cluster-backup::2024_07_21_Immich_Images_initial /data/raid/cubes/immich-immich-library-pvc-2af9ddd9-b982-4465-af2f-f8a8a3b1aee3
