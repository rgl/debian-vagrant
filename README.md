This builds an up-to-date Vagrant Debian Base Box.

Currently this targets [Debian Stretch 9.4](https://www.debian.org/releases/stretch/).


# Usage

Install [Packer](https://www.packer.io/), [Vagrant](https://www.vagrantup.com/) and [VirtualBox](https://www.virtualbox.org/).

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
vagrant plugin install vagrant-libvirt
vagrant up --provider=libvirt
vagrant ssh
exit
vagrant destroy -f
```


## VirtualBox usage

Install [VirtuaBox](https://www.virtualbox.org/).
On Linux
Type `make build-virtualbox` and follow the instructions.

On windows
Run packer to create the base box.
In root directory, (for me, E:\projects\deb-base\debian-vagrant> )
Check source iso is correct version and update checksum.

```bash
packer validate debian.json
packer build debian.json
```
If build is successful add box to vb

```bash
vagrant box list
vagrant box add debian-9-amd64 debian-9-amd64.box
vagrant box list
```

Try the example guest:

```bash
cd example
vagrant up --provider=virtualbox
vagrant ssh
exit
vagrant destroy -f
```


# Preseed

The debian installation iso uses the debian installer (aka d-i) to install
debian. During the installation it will ask you some questions and it will
also store your anwsers in the debconf database. After the installation is
complete, you can see its contents with the following commands:

```bash
sudo su -l
apt-get install debconf-utils
debconf-get-selections --installer
```

In reality, before d-i asks a question, it will first look for the answer in
its database, if its there, it will automatically continue the installation
without asking the question at all.

To automate the installation, the database is populated from a
[preseed.txt](preseed.txt) text file. d-i will get its location from the
kernel command line `url` argument. Which will be a http address served by
packer during the machine provisioning.


# Reference

* Debian Stretch [Appendix B. Automating the installation using preseeding](https://www.debian.org/releases/stretch/amd64/apb.html.en)
* Debian Stretch [example-preseed.txt](https://www.debian.org/releases/stretch/example-preseed.txt)
