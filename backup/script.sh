#!/usr/bin/env bash

##
## Set environment variables
##

## if you don't use the standard SSH key,
## you have to specify the path to the key like this
# export BORG_RSH='ssh -i /home/userXY/.ssh/id_ed25519'

## You can save your borg passphrase in an environment
## variable, so you don't need to type it in when using borg
export BORG_PASSPHRASE='SECRET'

##
## Set some variables
##

export LOG='/var/log/borg/backup.log'
export BACKUP_USER='uXXXXXX'
export REPOSITORY_DIR='cluster-backup'

## Tip: If using with a Backup Space you have to use
## 'your-storagebox.de' instead of 'your-backup.de'

export REPOSITORY="ssh://${BACKUP_USER}@${BACKUP_USER}.your-storagebox.de:23/./${REPOSITORY_DIR}"

##
## Output to a logfile
##

exec > >(tee -i ${LOG})
exec 2>&1

echo "###### Backup started: $(date) ######"

##
## At this place you could perform different tasks
## that will take place before the backup, e.g.
##
## - Create a list of installed software
## - Create a database dump
##

##
## Transfer the files into the repository.
## In this example the folders root, etc,
## var/www and home will be saved.
## In addition you find a list of excludes that should not
## be in a backup and are excluded by default.
##

echo "Backing up k3s ..."
borg create --stats                                 \
    $REPOSITORY::'k3s-{now:%Y-%m-%d_%H:%M}'         \
    /var/lib/rancher/k3s/server/db/snapshots

echo "Backing up cube PVCs ..."
borg create --stats                   \
    $REPOSITORY::'cubes-{now:%Y-%m-%d_%H:%M}'                                                                       \
    /data/raid/cubes                                                                                                \
    --exclude /data/raid/cubes/jellyfin-jellyfin-media-pvc-29eeb2d3-e6b4-43c0-8067-7152203615f0                     \
    --exclude /data/raid/cubes/immich-immich-machine-learning-cache-pvc-e7659a22-496f-4cab-a554-3a4fdf2677d6        \
    --exclude /data/raid/cubes/paperless-paperless-consume-pvc-1eebc996-fa85-4438-8173-1bb29399e34c                 \
    --exclude /data/raid/cubes/kube-system-traefik-pvc-aeb1e86f-9595-4ee9-8f93-33b33d7269b4                         \
    --exclude /data/raid/cubes/audiobookshelf-audiobookshelf-audiobooks-pvc-fd18bca7-a973-451d-98f8-1de0de0a440d    \
    --exclude /data/raid/cubes/audiobookshelf-audiobookshelf-podcasts-pvc-596128f3-5a0d-402a-b08f-699454e0b4dc

echo "###### Backup ended: $(date) ######"