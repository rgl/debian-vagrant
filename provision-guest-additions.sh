#!/bin/bash
set -eux

# install the Guest Additions.
if [ -n "$(lspci | grep VirtualBox | head -1)" ]; then
# install the VirtualBox Guest Additions.
# this will be installed at /opt/VBoxGuestAdditions-VERSION.
# REMOVE_INSTALLATION_DIR=0 is to fix a bug in VBoxLinuxAdditions.run.
# See http://stackoverflow.com/a/25943638.
apt-get -y -q install gcc dkms bzip2
mkdir -p /media/iso
mount -o loop /home/vagrant/VBoxGuestAdditions.iso /media/iso
while [ ! -f /media/iso/VBoxLinuxAdditions.run ]; do sleep 1; done
# NB we assume this command will always succeed due to:
#       VirtualBox Guest Additions: Running kernel modules will not be replaced until the system is restarted
REMOVE_INSTALLATION_DIR=0 \
    /media/iso/VBoxLinuxAdditions.run \
        --target /tmp/VBoxGuestAdditions \
    || true
rm -rf /tmp/VBoxGuestAdditions
umount /media/iso
rm -rf /media/iso /home/vagrant/VBoxGuestAdditions.iso
modinfo vboxguest
elif [ -n "$(lspci | grep 'Red Hat' | head -1)" ]; then
# install the qemu-kvm Guest Additions.
apt-get install -y qemu-guest-agent spice-vdagent
elif [ -n "$(lspci | grep VMware | head -1)" ]; then
# install the VMware Guest Additions.
apt-get install -y open-vm-tools
else
echo 'ERROR: Unknown VM host.' || exit 1
fi

# reboot.
nohup bash -c "ps -eo pid,comm | awk '/sshd/{print \$1}' | xargs kill; sync; reboot"
