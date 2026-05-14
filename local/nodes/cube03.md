## Raid

```bash
root@cube03:~# cat /proc/mdstat
Personalities : [raid1]
md0 : active raid1 sda1[0] sdb1[1]
      15625745408 blocks super 1.2 [2/2] [UU]
      bitmap: 2/117 pages [8KB], 65536KB chunk

unused devices: <none>
root@cube03:~# grep '^ARRAY' /etc/mdadm/mdadm.conf
root@cube03:~# cat /etc/mdadm/mdadm.conf
# mdadm.conf
#
# !NB! Run update-initramfs -u after updating this file.
# !NB! This will ensure that initramfs has an uptodate copy.
#
# Please refer to mdadm.conf(5) for information about this file.
#

# by default (built-in), scan all partitions (/proc/partitions) and all
# containers for MD superblocks. alternatively, specify devices to scan, using
# wildcards if desired.
#DEVICE partitions containers

# automatically tag new arrays as belonging to the local system
HOMEHOST <system>

# instruct the monitoring daemon where to send mail alerts
MAILADDR root

# definitions of existing MD arrays

# This configuration was auto-generated on Sun, 23 Apr 2023 14:24:27 +0200 by mkconf
root@cube03:~# sudo lvs
sudo: lvs: command not found
root@cube03:~# sudo pvs
sudo: pvs: command not found
root@cube03:~# df -h
Filesystem      Size  Used Avail Use% Mounted on
/dev/root        29G   17G   11G  61% /
devtmpfs        1.9G     0  1.9G   0% /dev
tmpfs           1.9G     0  1.9G   0% /dev/shm
tmpfs           769M   94M  676M  13% /run
tmpfs           5.0M     0  5.0M   0% /run/lock
tmpfs           1.9G     0  1.9G   0% /tmp
tmpfs            50M  1.7M   49M   4% /var/log
/dev/mmcblk0p1  127M   33M   95M  26% /boot
/dev/md0         15T  7.4T  6.4T  54% /data/raid
```
