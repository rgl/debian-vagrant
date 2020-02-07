Download the [ESXi](https://www.vmware.com/go/get-free-esxi) ISO file.

Install it into a VM that has nested virtualization support. In my case, I've used libvirt and Virtual Machine Manager to create a KVM VM with a `host-passthrough` (for nested-virtualization) CPU type, a e1000 network interface connected to a 10.2.0.0/24 NAT network, a 80GB IDE disk and 8192MB (8GB) of memory.

**NB** For the examples to work, make sure you set the `root` password to `HeyH0Password`.

**NB** The examples assume ESXi is at the `10.2.0.198` address.

Once ESXi is installed, access the [HTML UI](https://10.2.0.198) and enable SSH through the `Host | Manage | Services | Right click the TSM-SSH service | Policy | Start and stop with host` then `Start` it.

Upgrade ESXi by grabbing the latest imageprofile from https://esxi-patches.v-front.de/ESXi-6.7.0.html and follow the instructions. At the time of writing, the latest imageprofile was ESXi-6.7.0-20181104001-standard (Build 10764712) and the instructions were:

```bash
# ssh into ESXi and enter the maintenance mode.
ssh root@10.2.0.198
vim-cmd hostsvc/maintenance_mode_enter

# see current version.
esxcli system version get
esxcli network ip connection list

# upgrade.
# NB if you are having trouble to install the upgrade, increase the memory of the VM.
esxcli network firewall ruleset set -e true -r httpClient
esxcli software profile update -p ESXi-6.7.0-20190104001-standard \
  -d https://hostupdate.vmware.com/software/VUM/PRODUCTION/main/vmw-depot-index.xml
esxcli network firewall ruleset set -e false -r httpClient

# NB I was having problems (even after configuring the swap inside datastore1):
#       [InstallationError]
#       [Errno 28] No space left on device
#             vibs = VMware_locker_tools-light_10.3.2.9925305-10176879
#       Please refer to the log file for more details.
#    checking the logs at /var/log/esxupdate.log lead me to manually download and install this vib:
#       2019-01-05T11:52:26Z esxupdate: 2099679: downloader: INFO: Downloading https://hostupdate.vmware.com/software/VUM/PRODUCTION/main/esx/vmw/vib20/tools-light/VMware_locker_tools-light_10.3.2.9925305-10176879.vib to /tmp/vibdownload/VMware_locker_tools-light_10.3.2.9925305-10176879.vib
#    so I've installed it and repeated the upgrade process, and it succeeded.
cd /vmfs/volumes/datastore1
# NB wget on esxi does not support https, so I've changed the url to http.
wget http://hostupdate.vmware.com/software/VUM/PRODUCTION/main/esx/vmw/vib20/tools-light/VMware_locker_tools-light_10.3.2.9925305-10176879.vib
esxcli software vib install -v $PWD/VMware_locker_tools-light_10.3.2.9925305-10176879.vib
rm VMware_locker_tools-light_10.3.2.9925305-10176879.vib
# NB you must now repeat the upgrade process and then continue from here.

# reboot to complete the upgrade.
reboot

# ssh into ESXi and exit the maintenance mode.
ssh root@10.2.0.198
vim-cmd hostsvc/maintenance_mode_exit

# verify the version and exit.
esxcli system version get
exit
```

**NB** view the logs at /var/log/esxupdate.log (or https://10.2.0.198/ui/#/host/monitor/logs).

**NB** if the update fails with a `No Space Left On Device` error, set the swap datastore to `datastore1` at `Host | Manage | System | Swap`.

Download the [ovftool bundle](https://code.vmware.com/tool/ovf) and save it as the `ovftool.bundle` file, then install it with, e.g.:

```bash
TERM=dumb sh ovftool.bundle --eulas-agreed --required --prefix=/opt/ovftool
ln -s /opt/ovftool/lib/vmware-ovftool/ovftool /usr/local/bin/
ovftool --version
```

Enable guest ARP inspection to get IP (aka the Guest IP Hack):

```bash
ssh root@10.2.0.198
esxcli system settings advanced list -o /Net/GuestIPHack
esxcli system settings advanced set -o /Net/GuestIPHack -i 1
```

Configure the firewall to allow VNC access:

```bash
stat /etc/vmware/firewall/service.xml
chmod 644 /etc/vmware/firewall/service.xml
chmod +t /etc/vmware/firewall/service.xml
grep '<id>vnc</id>' /etc/vmware/firewall/service.xml || sed -i -E 's,(</ConfigRoot>),<service id="1000"><id>vnc</id><rule id="0000"><direction>inbound</direction><protocol>tcp</protocol><porttype>dst</porttype><port><begin>5900</begin><end>6000</end></port></rule></service>\n\1,' /etc/vmware/firewall/service.xml
vi /etc/vmware/firewall/service.xml
```

Refresh the firewall:

```bash
esxcli network firewall refresh
esxcli network firewall ruleset set --ruleset-id vnc --enabled true
esxcli network firewall ruleset list | grep vnc
esxcli network firewall ruleset rule list | grep vnc
```

**NB** You **MUST** re-apply the above firewall changes every time ESXi (re)boots.


# Tips

## ovftool

* You can enable verbose logging:

    ```
    ovftool --X:logToConsole --X:logLevel=verbose ...
    ```

* Show a VM details, e.g. show the `example` VM details:

    ```
    ovftool --noSSLVerify=true vi://root:HeyH0Password@10.2.0.198/example
    ```
