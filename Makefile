VERSION=$(shell jq -r .variables.version debian.json)

help:
	@echo type make build-libvirt or make build-virtualbox

build-libvirt: debian-${VERSION}-amd64-libvirt.box

build-virtualbox: debian-${VERSION}-amd64-virtualbox.box

debian-${VERSION}-amd64-libvirt.box: preseed.txt provision.sh debian.json Vagrantfile.template
	rm -f debian-${VERSION}-amd64-libvirt.box
	PACKER_KEY_INTERVAL=10ms packer build -only=debian-${VERSION}-amd64-libvirt -on-error=abort debian.json
	@echo BOX successfully built!
	@echo to add to local vagrant install do:
	@echo vagrant box add -f debian-${VERSION}-amd64 debian-${VERSION}-amd64-libvirt.box

debian-${VERSION}-amd64-virtualbox.box: preseed.txt provision.sh debian.json Vagrantfile.template
	rm -f debian-${VERSION}-amd64-virtualbox.box
	packer build -only=debian-${VERSION}-amd64-virtualbox -on-error=abort debian.json
	@echo BOX successfully built!
	@echo to add to local vagrant install do:
	@echo vagrant box add -f debian-${VERSION}-amd64 debian-${VERSION}-amd64-virtualbox.box

.PHONY: buid-libvirt build-virtualbox
