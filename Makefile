VERSION=$(shell jq -r .variables.version debian.json)

help:
	@echo type make build-libvirt, make build-virtualbox or make build-esxi
	@echo to troubleshoot, set the following environment variables before calling make:
	@echo 	export PACKER_LOG=1 PACKER_LOG_PATH=packer.log

build-libvirt: debian-${VERSION}-amd64-libvirt.box
build-virtualbox: debian-${VERSION}-amd64-virtualbox.box
build-esxi: debian-${VERSION}-amd64-esxi.box

debian-${VERSION}-amd64-libvirt.box: preseed.txt provision.sh debian.json Vagrantfile.template
	rm -f debian-${VERSION}-amd64-libvirt.box
	PACKER_KEY_INTERVAL=10ms CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$@.log \
		packer build -only=debian-${VERSION}-amd64-libvirt -on-error=abort debian.json
	@echo BOX successfully built!
	@echo to add to local vagrant install do:
	@echo vagrant box add -f debian-${VERSION}-amd64 debian-${VERSION}-amd64-libvirt.box

debian-${VERSION}-amd64-virtualbox.box: preseed.txt provision.sh debian.json Vagrantfile.template
	rm -f debian-${VERSION}-amd64-virtualbox.box
	CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$@.log \
		packer build -only=debian-${VERSION}-amd64-virtualbox -on-error=abort debian.json
	@echo BOX successfully built!
	@echo to add to local vagrant install do:
	@echo vagrant box add -f debian-${VERSION}-amd64 debian-${VERSION}-amd64-virtualbox.box

debian-${VERSION}-amd64-esxi.box: preseed.txt provision.sh debian-esxi.json dummy-esxi.box
	rm -f debian-${VERSION}-amd64-esxi.box
	PACKER_KEY_INTERVAL=10ms PACKER_ESXI_VNC_PROBE_TIMEOUT=15s CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$@.log \
		packer build -only=debian-${VERSION}-amd64-esxi debian-esxi.json
	@echo BOX successfully built!
	@echo to add to local vagrant install do:
	@echo vagrant box add -f dummy dummy-esxi.box

dummy-esxi.box:
	echo '{"provider":"vmware_esxi"}' >metadata.json
	tar cvf $@ metadata.json
	rm metadata.json

.PHONY: buid-libvirt build-virtualbox build-esxi
