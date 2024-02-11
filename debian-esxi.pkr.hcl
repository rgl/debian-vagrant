packer {
  required_plugins {
    # see https://github.com/hashicorp/packer-plugin-vmware
    vmware = {
      version = "1.0.11"
      source  = "github.com/hashicorp/vmware"
    }
  }
}

variable "version" {
  type = string
}

variable "disk_size" {
  type    = string
  default = 8 * 1024
}

variable "iso_url" {
  type    = string
  default = "https://cdimage.debian.org/debian-cd/12.5.0/amd64/iso-cd/debian-12.5.0-amd64-netinst.iso"
}

variable "iso_checksum" {
  type    = string
  default = "sha256:013f5b44670d81280b5b1bc02455842b250df2f0c6763398feb69af1a805a14f"
}

variable "esxi_host" {
  type    = string
  default = "esxi.test"
}

variable "esxi_username" {
  type    = string
  default = "root"
}

variable "esxi_password" {
  type    = string
  default = "HeyH0Password!"
}

variable "esxi_datastore" {
  type    = string
  default = "datastore1"
}

variable "esxi_network" {
  type    = string
  default = "VM Network"
}

source "vmware-iso" "debian-amd64" {
  vm_name              = "debian-${var.version}-amd64"
  version              = "20"
  guest_os_type        = "debian12-64"
  headless             = true
  http_directory       = "."
  disk_size            = var.disk_size
  disk_type_id         = "thin"
  disk_adapter_type    = "pvscsi"
  tools_upload_flavor  = ""
  format               = "vmx"
  remote_type          = "esx5"
  remote_host          = var.esxi_host
  remote_username      = var.esxi_username
  remote_password      = var.esxi_password
  remote_datastore     = var.esxi_datastore
  skip_export          = true
  keep_registered      = true
  vnc_over_websocket   = true
  network_adapter_type = "vmxnet3"
  cpus                 = 4
  cores                = 4
  memory               = 2 * 1024
  network_name         = var.esxi_network
  iso_url              = var.iso_url
  iso_checksum         = var.iso_checksum
  ssh_username         = "vagrant"
  ssh_password         = "vagrant"
  ssh_timeout          = "60m"
  boot_wait            = "15s"
  boot_command = [
    "<tab>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "/install.amd/vmlinuz initrd=/install.amd/initrd.gz",
    " auto=true",
    " url={{.HTTPIP}}:{{.HTTPPort}}/preseed.txt",
    " hostname=vagrant",
    " domain=home",
    " net.ifnames=0",
    " fb=false",
    " BOOT_DEBUG=2",
    " DEBCONF_DEBUG=5",
    "<enter>",
  ]
  shutdown_command = "echo vagrant | sudo -S poweroff"
}

build {
  sources = [
    "source.vmware-iso.debian-amd64",
  ]

  provisioner "shell" {
    expect_disconnect = true
    execute_command   = "echo vagrant | sudo -S {{ .Vars }} bash {{ .Path }}"
    scripts = [
      "provision-guest-additions.sh",
      "provision.sh"
    ]
  }
}
