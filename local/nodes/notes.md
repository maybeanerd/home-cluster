Step-by-Step Migration for Your Specific SystemSince you are not using LVM and this is a data-only array, use these precise commands:1. On the Current Machine (cube03)Stop the services using the data, then safely unmount and stop the array:bashsudo umount /data/raid
sudo mdadm --stop /dev/md0
Use code with caution.You can now safely power down cube03 and pull the two hard drives (sda and sdb).2. On the New MachinePhysically attach the two drives to the new machine.Step A: Install Software & Detect DisksEnsure the tools are installed and check if the OS sees the raw disks:bashsudo apt update && sudo apt install mdadm -y
lsblk
Use code with caution.(Verify you see the two disks listed, likely as sda/sdb or sdb/sdc depending on the new hardware).Step B: Assemble the ArrayForce a scan and reassemble the existing RAID1 structure:bashsudo mdadm --assemble --scan
Use code with caution.Check if the array successfully started:bashcat /proc/mdstat
Use code with caution.(It will likely show up as /dev/md0 or /dev/md127 due to the <system> homehost configuration).Step C: Make it PermanentCreate a mounting directory and test the mount manually:bashsudo mkdir -p /data/raid
sudo mount /dev/md127 /data/raid  # Use the actual mdX name from /proc/mdstat
Use code with caution.Save the configuration so it loads automatically on boot:bashsudo mdadm --detail --scan | sudo tee -a /etc/mdadm/mdadm.conf
sudo update-initramfs -u
