This builds an up-to-date Vagrant Debian Base Box.

Currently this targets [Debian Stretch 9](https://www.debian.org/releases/stretch/).


# Usage

Install [Packer](https://www.packer.io/), [Vagrant](https://www.vagrantup.com/) and [VirtualBox](https://www.virtualbox.org/).

Type `make` and follow the instructions.

Try the example guest:

```bash
cd example
vagrant up
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
