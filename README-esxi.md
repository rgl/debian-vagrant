Download the [ESXi](https://www.vmware.com/go/get-free-esxi) ISO file.

Install it into a VM that has nested virtualization support. In my case, I've used libvirt and Virtual Machine Manager to create a KVM VM connected to a NAT network (with a e1000 nic), 80G disk and 5G memory.

**NB** For the examples to work, make sure you set the `root` password to `HeyH0Password`.

**NB** The examples assume ESXi is at the `10.2.0.198` address.

Once ESXi is installed, access the HTML UI and enable SSH through the `Host | Manager | Services | Right click the TSM-SSH service | Policy | Start and stop with host` then `Start` it.

Upgrade ESXi by grabbing the latest imageprofile from https://esxi-patches.v-front.de/ESXi-6.5.0.html and follow the instructions. At the time of writing, the latest imageprofile was ESXi-6.5.0-20171204001-standard (Build 7388607) and the instructions were:

```bash
# ssh into the ESXi.
ssh root@10.2.0.198

# see current version.
esxcli system version get
esxcli network ip connection list

# upgrade.
esxcli network firewall ruleset set -e true -r httpClient
esxcli software profile update -p ESXi-6.5.0-20171204001-standard \
  -d https://hostupdate.vmware.com/software/VUM/PRODUCTION/main/vmw-depot-index.xml
esxcli network firewall ruleset set -e false -r httpClient

# reboot to complete the upgrade.
reboot
```

**NB** if the update fails with a `No Space Left On Device Error`, set the swap datastore at `Host | Manage | System | Swap`.

Install [ovftool](https://www.vmware.com/support/developer/ovf/).

Enable guest ARP inspection to get IP (aka the Guest IP Hack):

```bash
ssh root@10.2.0.198
esxcli system settings advanced list -o /Net/GuestIPHack
esxcli system settings advanced set -o /Net/GuestIPHack -i 1
```

Configure the firewall to allow VNC access:

```
stat /etc/vmware/firewall/service.xml
chmod 644 /etc/vmware/firewall/service.xml
chmod +t /etc/vmware/firewall/service.xml
vi /etc/vmware/firewall/service.xml
```

Add the following element to the end of the `service.xml` document:

```xml
  <service id="1000">
    <id>vnc</id>
    <rule id="0000">
      <direction>inbound</direction>
      <protocol>tcp</protocol>
      <porttype>dst</porttype>
      <port>
        <begin>5900</begin>
        <end>6000</end>
      </port>
    </rule>
  </service>
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
