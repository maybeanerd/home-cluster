# Setup

## Preparation

First, ensure that Samba is installed on your system:

```bash
sudo apt-get update
sudo apt-get install samba
```

## Configuration

We adjust the Samba configuration file `/etc/samba/smb.conf` to set up our shared directories and permissions.

To add a new share, we append the following configuration to the end of the `smb.conf` file:

```ini
# jellyfin media
[jellyfinMedia]
path = /data/raid/cubes/jellyfin-jellyfin-media-pvc-29eeb2d3-e6b4-43c0-8067-7152203615f0/nas/
writeable = yes
create mask = 0775
directory mask = 0775
public=no
```

Then, run the following command to restart the Samba service and apply the new configuration:

```bash
sudo systemctl restart smbd
```

