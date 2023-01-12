SHELL=bash
.SHELLFLAGS=-euo pipefail -c

VERSION=$(shell jq -r .variables.version debian.json)

help:
	@echo type make build-libvirt, make build-uefi-libvirt, make build-virtualbox, make build-hyperv, make build-vsphere or make build-esxi

build-libvirt: debian-${VERSION}-amd64-libvirt.box
build-uefi-libvirt: debian-${VERSION}-uefi-amd64-libvirt.box
build-virtualbox: debian-${VERSION}-amd64-virtualbox.box
build-hyperv: debian-${VERSION}-amd64-hyperv.box
build-vsphere: debian-${VERSION}-amd64-vsphere.box
build-esxi: debian-${VERSION}-amd64-esxi.box

debian-${VERSION}-amd64-libvirt.box: preseed.txt provision.sh debian.json Vagrantfile.template
	rm -f $@
	PACKER_KEY_INTERVAL=10ms CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$@.log \
		packer build -only=debian-${VERSION}-amd64-libvirt -on-error=abort -timestamp-ui debian.json
	@./box-metadata.sh libvirt debian-${VERSION}-amd64 $@

debian-${VERSION}-uefi-amd64-libvirt.box: preseed.txt provision.sh debian.json Vagrantfile-uefi.template
	rm -f $@
	PACKER_KEY_INTERVAL=10ms CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$@.log \
		packer build -only=debian-${VERSION}-uefi-amd64-libvirt -on-error=abort -timestamp-ui debian.json
	@./box-metadata.sh libvirt debian-${VERSION}-uefi-amd64 $@

debian-${VERSION}-amd64-virtualbox.box: preseed.txt provision.sh debian.json Vagrantfile.template
	rm -f $@
	CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$@.log \
		packer build -only=debian-${VERSION}-amd64-virtualbox -on-error=abort -timestamp-ui debian.json
	@./box-metadata.sh virtualbox debian-${VERSION}-amd64 $@

debian-${VERSION}-amd64-hyperv.box: tmp/preseed-hyperv.txt provision.sh debian.json Vagrantfile.template
	rm -f $@
	CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$@.log \
		packer build -only=debian-${VERSION}-amd64-hyperv -on-error=abort -timestamp-ui debian.json
	@./box-metadata.sh hyperv debian-${VERSION}-amd64 $@

# see https://docs.microsoft.com/en-us/windows-server/virtualization/hyper-v/supported-debian-virtual-machines-on-hyper-v
tmp/preseed-hyperv.txt: preseed.txt
	mkdir -p tmp
	sed -E 's,(d-i pkgsel/include string .+),\1 hyperv-daemons,g' preseed.txt >$@

debian-${VERSION}-amd64-vsphere.box: tmp/preseed-vsphere.txt provision.sh debian-vsphere.json Vagrantfile.template dummy-vsphere.box
	rm -f $@
	CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$@.log \
		packer build -only=debian-${VERSION}-amd64-vsphere -timestamp-ui debian-vsphere.json
	@./box-metadata.sh vsphere debian-${VERSION}-amd64 $@

debian-${VERSION}-amd64-esxi.box: preseed.txt provision.sh debian-esxi.json dummy-esxi.box
	rm -f $@
	PACKER_KEY_INTERVAL=10ms PACKER_ESXI_VNC_PROBE_TIMEOUT=15s CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$@.log \
		packer build -only=debian-${VERSION}-amd64-esxi -timestamp-ui debian-esxi.json
	@echo BOX successfully built!
	@echo to add to local vagrant install do:
	@echo vagrant box add -f dummy dummy-esxi.box

tmp/preseed-vsphere.txt: preseed.txt
	mkdir -p tmp
	sed -E 's,(d-i pkgsel/include string .+),\1 open-vm-tools,g' preseed.txt >$@

dummy-vsphere.box:
	echo '{"provider":"vsphere"}' >metadata.json
	tar cvf $@ metadata.json
	rm metadata.json

dummy-esxi.box:
	echo '{"provider":"vmware_esxi"}' >metadata.json
	tar cvf $@ metadata.json
	rm metadata.json

.PHONY: help buid-libvirt buid-uefi-libvirt build-virtualbox build-vsphere build-esxi
