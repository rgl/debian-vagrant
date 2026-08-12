SHELL=bash
.SHELLFLAGS=-euo pipefail -c

VERSION=13

export PROXMOX_URL?=https://192.168.1.21:8006/api2/json
export PROXMOX_USERNAME?=root@pam
export PROXMOX_PASSWORD?=vagrant
export PROXMOX_NODE?=pve

help:
	@echo type one of:
	@echo	make build-uefi-hyperv
	@echo	make build-uefi-libvirt
	@echo	make build-uefi-proxmox
	@echo	make build-uefi-vsphere

build-uefi-libvirt: debian-${VERSION}-uefi-amd64-libvirt.box
build-uefi-proxmox: debian-${VERSION}-uefi-amd64-proxmox.box
build-uefi-hyperv: debian-${VERSION}-uefi-amd64-hyperv.box
build-uefi-vsphere: debian-${VERSION}-uefi-amd64-vsphere.box

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

debian-${VERSION}-uefi-amd64-proxmox.box: preseed.txt provision.sh debian.pkr.hcl Vagrantfile-uefi.template
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
		packer build -only=proxmox-iso.debian-uefi-amd64 -on-error=abort -timestamp-ui debian.pkr.hcl

debian-${VERSION}-uefi-amd64-hyperv.box: tmp/preseed-hyperv.txt provision.sh debian.pkr.hcl Vagrantfile-uefi.template
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
		packer build -only=hyperv-iso.debian-uefi-amd64 -on-error=abort -timestamp-ui debian.pkr.hcl
	@./box-metadata.sh hyperv debian-${VERSION}-uefi-amd64 $@

# see https://docs.microsoft.com/en-us/windows-server/virtualization/hyper-v/supported-debian-virtual-machines-on-hyper-v
# see https://packages.debian.org/trixie/hyperv-daemons
tmp/preseed-hyperv.txt: preseed.txt
	mkdir -p tmp
	sed -E 's,(d-i pkgsel/include string .+),\1 hyperv-daemons,g' preseed.txt >$@

debian-${VERSION}-uefi-amd64-vsphere.box: tmp/preseed-vsphere.txt provision.sh debian-vsphere.pkr.hcl Vagrantfile-uefi.template
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
		packer build -only=vsphere-iso.debian-uefi-amd64 -timestamp-ui debian-vsphere.pkr.hcl
	echo '{"provider":"vsphere"}' >metadata.json
	tar cvf $@ metadata.json
	rm metadata.json
	@./box-metadata.sh vsphere debian-${VERSION}-uefi-amd64 $@

# see https://packages.debian.org/trixie/open-vm-tools
tmp/preseed-vsphere.txt: preseed.txt
	mkdir -p tmp
	sed -E 's,(d-i pkgsel/include string .+),\1 open-vm-tools,g' preseed.txt >$@

.PHONY: help \
	build-uefi-hyperv \
	build-uefi-libvirt \
	build-uefi-proxmox \
	build-uefi-vsphere
