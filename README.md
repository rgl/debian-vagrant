This builds an up-to-date Vagrant Debian Base Box.

Currently this targets [Debian Buster 10](https://www.debian.org/releases/buster/).


# Usage

## Ubuntu Host

On a Ubuntu host, install the dependencies by running the file at:

    https://github.com/rgl/xfce-desktop-vagrant/blob/master/provision-virtualization-tools.sh

And you should also install and configure the NFS server. E.g.:

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

## Windows Host

On a Windows host, install [Chocolatey](https://chocolatey.org/install), then execute the following PowerShell commands in a Administrator PowerShell window:

```powershell
choco install -y virtualbox --params "/NoDesktopShortcut /ExtensionPack"
choco install -y packer vagrant jq msys2
```

Then open a bash shell by starting `C:\tools\msys64\mingw64.exe` and install the remaining dependencies:

```bash
pacman --noconfirm -Sy make zip unzip tar dos2unix netcat procps xorriso mingw-w64-x86_64-libcdio
for n in /*.ini; do
    sed -i -E 's,^#?(MSYS2_PATH_TYPE)=.+,\1=inherit,g' $n
done
exit
```

**NB** The commands described in this README should be executed in a mingw64 bash shell.

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


## VMware vSphere usage

Download [govc](https://github.com/vmware/govmomi/releases/latest) and place it inside your `/usr/local/bin` directory.

Install the [vsphere vagrant plugin](https://github.com/nsidc/vagrant-vsphere), set your vSphere details, and test the connection to vSphere:

```bash
sudo apt-get install build-essential patch ruby-dev zlib1g-dev liblzma-dev
vagrant plugin install vagrant-vsphere
cd example
cat >secrets.sh <<EOF
export GOVC_INSECURE='1'
export GOVC_HOST='vsphere.local'
export GOVC_URL="https://$GOVC_HOST/sdk"
export GOVC_USERNAME='administrator@vsphere.local'
export GOVC_PASSWORD='password'
export GOVC_DATACENTER='Datacenter'
export GOVC_CLUSTER='Cluster'
export GOVC_DATASTORE='Datastore'
export VSPHERE_ESXI_HOST='esxi.local'
export VSPHERE_TEMPLATE_FOLDER='test/templates'
export VSPHERE_TEMPLATE_NAME="$VSPHERE_TEMPLATE_FOLDER/debian-10-amd64-vsphere"
export VSPHERE_VM_FOLDER='test'
export VSPHERE_VM_NAME='debian-vagrant-example'
export VSPHERE_VLAN='packer'
EOF
source secrets.sh
# see https://github.com/vmware/govmomi/blob/master/govc/USAGE.md
govc version
govc about
govc datacenter.info # list datacenters
govc find # find all managed objects
```

Download the Debian ISO (you can find the full iso URL in the [debian.json](debian.json) file) and place it inside the datastore as defined by the `vsphere_iso_url` user variable that is inside the [packer template](debian-vsphere.json).

See the [example Vagrantfile](example/Vagrantfile) to see how you could use a cloud-init configuration to configure the VM.

Type `make build-vsphere` and follow the instructions.

Try the example guest:

```bash
source secrets.sh
vagrant up --provider=vsphere
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
