This builds an up-to-date Vagrant Debian Base Box.

Currently this targets [Debian Buster 10](https://www.debian.org/releases/buster/).


# Usage

Install [Packer](https://www.packer.io/) and [Vagrant](https://www.vagrantup.com/).

If you are on a Debian/Ubuntu host, you should also install and configure the NFS server. E.g.:

```bash
# install the nfs server.
sudo apt-get install -y nfs-kernel-server

# enable password-less configuration of the nfs server exports.
sudo bash -c 'cat >/etc/sudoers.d/vagrant-synced-folders' <<'EOF'
Cmnd_Alias VAGRANT_EXPORTS_CHOWN = /bin/chown 0\:0 /tmp/*
Cmnd_Alias VAGRANT_EXPORTS_MV = /bin/mv -f /tmp/* /etc/exports
Cmnd_Alias VAGRANT_NFSD_CHECK = /etc/init.d/nfs-kernel-server status
Cmnd_Alias VAGRANT_NFSD_START = /etc/init.d/nfs-kernel-server start
Cmnd_Alias VAGRANT_NFSD_APPLY = /usr/sbin/exportfs -ar
%sudo ALL=(root) NOPASSWD: VAGRANT_EXPORTS_CHOWN, VAGRANT_EXPORTS_MV, VAGRANT_NFSD_CHECK, VAGRANT_NFSD_START, VAGRANT_NFSD_APPLY
EOF
```

For more information see the [Vagrant NFS documentation](https://www.vagrantup.com/docs/synced-folders/nfs.html).


## qemu-kvm usage

Install qemu-kvm:

```bash
apt-get install -y qemu-kvm
apt-get install -y sysfsutils
systool -m kvm_intel -v
```

Type `make build-libvirt` and follow the instructions.

Try the example guest:

```bash
cd example
apt-get install -y virt-manager libvirt-dev
vagrant plugin install vagrant-libvirt # see https://github.com/vagrant-libvirt/vagrant-libvirt
vagrant up --provider=libvirt
vagrant ssh
exit
vagrant destroy -f
```


## VirtualBox usage

Install [VirtuaBox](https://www.virtualbox.org/).

Type `make build-virtualbox` and follow the instructions.

Try the example guest:

```bash
cd example
vagrant up --provider=virtualbox
vagrant ssh
exit
vagrant destroy -f
```


## ESXi usage

[Install ESXi and ovftool](README-esxi.md).

Type `make build-esxi` and follow the instructions.

**NB** If this messes up, you might need to manually unregister the failed VM with, e.g.:

```bash
ssh root@10.2.0.198         # ssh into the esxi host.
vim-cmd vmsvc/getallvms     # list all vms and their id.
vim-cmd vmsvc/unregister 1  # unregister the vm with id 1.
```

**NB** When in doubt see [the packer esx5 driver source](https://github.com/hashicorp/packer/blob/master/builder/vmware/iso/driver_esx5.go).

Try the example guest:

```bash
cd example
vagrant plugin install vagrant-vmware-esxi # see https://github.com/josenk/vagrant-vmware-esxi
vagrant up --provider=vmware_esxi
vagrant ssh
exit
vagrant destroy -f
```


# Preseed

The debian installation iso uses the
[debian installer](https://wiki.debian.org/DebianInstaller) (aka d-i) to
install debian. During the installation it will ask you some questions and
it will also store your answers in the debconf database. After the
installation is complete, you can see its contents with the following
commands:

```bash
sudo su -l
apt-get install debconf-utils
debconf-get-selections --installer
less /var/log/installer/syslog
ls -la /var/log/installer/cdebconf
```

In reality, before d-i asks a question, it will first look for the answer in
its database, if its there, it will automatically continue the installation
without asking the question at all.

To automate the installation, the database is populated from a
[preseed.txt](preseed.txt) text file. d-i will get its location from the
kernel command line `url` argument. Which will be a http address served by
packer during the machine provisioning.


# Reference

* Debian Buster [Appendix B. Automating the installation using preseeding](https://www.debian.org/releases/buster/amd64/apb.en.html)
* Debian Buster [example-preseed.txt](https://www.debian.org/releases/buster/example-preseed.txt)
