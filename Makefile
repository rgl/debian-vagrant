VERSION=9

debian-${VERSION}-amd64-virtualbox.box: preseed.txt provision.sh debian.json
	rm -f debian-${VERSION}-amd64-virtualbox.box
	packer build debian.json
	@echo BOX successfully built!
	@echo to add to local vagrant install do:
	@echo vagrant box add -f debian-${VERSION}-amd64 debian-${VERSION}-amd64-virtualbox.box
