#!/bin/bash
set -eux

# install the Guest Additions.
if [ -n "$(lspci | grep 'Red Hat' | head -1)" ]; then
# install the qemu-kvm Guest Additions.
apt-get install -y qemu-guest-agent spice-vdagent
elif [ -n "$(lspci | grep VMware | head -1)" ]; then
# install the VMware Guest Additions.
apt-get install -y open-vm-tools
elif [ "$(cat /sys/devices/virtual/dmi/id/sys_vendor)" == 'Microsoft Corporation' ]; then
# no need to install the Hyper-V Guest Additions (aka Linux Integration Services)
# as they were already installed from tmp/preseed-hyperv.txt.
exit 0
else
echo 'ERROR: Unknown VM host.' || exit 1
fi

# reboot.
nohup bash -c "ps -eo pid,comm | awk '/sshd/{print \$1}' | xargs kill; sync; reboot"
