SHELL=bash
.SHELLFLAGS=-euo pipefail -c

VERSION=12

export PROXMOX_URL?=https://192.168.1.21:8006/api2/json
export PROXMOX_USERNAME?=root@pam
export PROXMOX_PASSWORD?=vagrant
export PROXMOX_NODE?=pve

help:
	@echo type make build-libvirt, make build-uefi-libvirt, make build-proxmox, make build-hyperv, or make build-vsphere

build-libvirt: debian-${VERSION}-amd64-libvirt.box
build-uefi-libvirt: debian-${VERSION}-uefi-amd64-libvirt.box
build-proxmox: debian-${VERSION}-amd64-proxmox.box
build-hyperv: debian-${VERSION}-amd64-hyperv.box
build-vsphere: debian-${VERSION}-amd64-vsphere.box

debian-${VERSION}-amd64-libvirt.box: preseed.txt provision.sh debian.pkr.hcl Vagrantfile.template
	rm -f $@
	CHECKPOINT_DISABLE=1 \
	PACKER_LOG=1 \
	PACKER_LOG_PATH=$@.init.log \
		packer init debian.pkr.hcl
	PACKER_KEY_INTERVAL=10ms \
	CHECKPOINT_DISABLE=1 \
	PACKER_LOG=1 \
	PACKER_LOG_PATH=$@.log \
	PKR_VAR_version=${VERSION} \
	PKR_VAR_vagrant_box=$@ \
		packer build -only=qemu.debian-amd64 -on-error=abort -timestamp-ui debian.pkr.hcl
	@./box-metadata.sh libvirt debian-${VERSION}-amd64 $@

debian-${VERSION}-uefi-amd64-libvirt.box: preseed.txt provision.sh debian.pkr.hcl Vagrantfile-uefi.template
	rm -f $@
	CHECKPOINT_DISABLE=1 \
	PACKER_LOG=1 \
	PACKER_LOG_PATH=$@.init.log \
		packer init debian.pkr.hcl
	PACKER_KEY_INTERVAL=10ms \
	CHECKPOINT_DISABLE=1 \
	PACKER_LOG=1 PACKER_LOG_PATH=$@.log \
	PKR_VAR_version=${VERSION} \
	PKR_VAR_vagrant_box=$@ \
		packer build -only=qemu.debian-uefi-amd64 -on-error=abort -timestamp-ui debian.pkr.hcl
	@./box-metadata.sh libvirt debian-${VERSION}-uefi-amd64 $@

debian-${VERSION}-amd64-proxmox.box: preseed.txt provision.sh debian.pkr.hcl Vagrantfile-uefi.template
	rm -f $@
	CHECKPOINT_DISABLE=1 \
	PACKER_LOG=1 \
	PACKER_LOG_PATH=$@.init.log \
		packer init debian.pkr.hcl
	CHECKPOINT_DISABLE=1 \
	PACKER_LOG=1 \
	PACKER_LOG_PATH=$@.log \
	PKR_VAR_version=${VERSION} \
	PKR_VAR_vagrant_box=$@ \
		packer build -only=proxmox-iso.debian-amd64 -on-error=abort -timestamp-ui debian.pkr.hcl

debian-${VERSION}-amd64-hyperv.box: tmp/preseed-hyperv.txt provision.sh debian.pkr.hcl Vagrantfile.template
	rm -f $@
	CHECKPOINT_DISABLE=1 \
	PACKER_LOG=1 \
	PACKER_LOG_PATH=$@.init.log \
		packer init debian.pkr.hcl
	CHECKPOINT_DISABLE=1 \
	PACKER_LOG=1 \
	PACKER_LOG_PATH=$@.log \
	PKR_VAR_version=${VERSION} \
	PKR_VAR_vagrant_box=$@ \
		packer build -only=hyperv-iso.debian-amd64 -on-error=abort -timestamp-ui debian.pkr.hcl
	@./box-metadata.sh hyperv debian-${VERSION}-amd64 $@

# see https://docs.microsoft.com/en-us/windows-server/virtualization/hyper-v/supported-debian-virtual-machines-on-hyper-v
tmp/preseed-hyperv.txt: preseed.txt
	mkdir -p tmp
	sed -E 's,(d-i pkgsel/include string .+),\1 hyperv-daemons,g' preseed.txt >$@

debian-${VERSION}-amd64-vsphere.box: tmp/preseed-vsphere.txt provision.sh debian-vsphere.pkr.hcl Vagrantfile.template
	rm -f $@
	CHECKPOINT_DISABLE=1 \
	PACKER_LOG=1 \
	PACKER_LOG_PATH=$@.init.log \
		packer init debian-vsphere.pkr.hcl
	CHECKPOINT_DISABLE=1 \
	PACKER_LOG=1 \
	PACKER_LOG_PATH=$@.log \
	PKR_VAR_version=${VERSION} \
	PKR_VAR_vagrant_box=$@ \
		packer build -only=vsphere-iso.debian-amd64 -timestamp-ui debian-vsphere.pkr.hcl
	echo '{"provider":"vsphere"}' >metadata.json
	tar cvf $@ metadata.json
	rm metadata.json
	@./box-metadata.sh vsphere debian-${VERSION}-amd64 $@

tmp/preseed-vsphere.txt: preseed.txt
	mkdir -p tmp
	sed -E 's,(d-i pkgsel/include string .+),\1 open-vm-tools,g' preseed.txt >$@

.PHONY: help buid-libvirt buid-uefi-libvirt build-proxmox build-vsphere
