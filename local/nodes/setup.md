## General Setup for RK1 Node

Follow [the turingpi guide](https://docs.turingpi.com/docs/turing-rk1-flashing-os):

- flash using the BMC https://docs.turingpi.com/docs/turing-rk1-flashing-os#flashing-using-turing-pi-2-bmc
- post install tasks https://docs.turingpi.com/docs/turing-rk1-flashing-os#post-install-tasks , keep at performance
- copy system to NVME SSD https://docs.turingpi.com/docs/turing-rk1-flashing-os#running-off-an-external-block-device---method-2

## configure cgroup for k3s to run on the node

We need to have `/proc/cmdline` include `systemd.unified_cgroup_hierarchy=1` instead of `=0`

For this, we want to edit the file that fills it:
```bash
sudo nano /boot/firmware/ubuntuEnv.txt
``
