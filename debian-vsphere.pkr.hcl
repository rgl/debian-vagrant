packer {
  required_plugins {
    # see https://github.com/hashicorp/packer-plugin-vsphere
    vsphere = {
      version = "1.4.2"
      source  = "github.com/hashicorp/vsphere"
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

variable "vsphere_iso_url" {
  type    = string
  default = env("VSPHERE_OS_ISO")
}

variable "vsphere_host" {
  type    = string
  default = env("GOVC_HOST")
}

variable "vsphere_username" {
  type    = string
  default = env("GOVC_USERNAME")
}

variable "vsphere_password" {
  type    = string
  default = env("GOVC_PASSWORD")
}

variable "vsphere_esxi_host" {
  type    = string
  default = env("VSPHERE_ESXI_HOST")
}

variable "vsphere_datacenter" {
  type    = string
  default = env("GOVC_DATACENTER")
}

variable "vsphere_cluster" {
  type    = string
  default = env("GOVC_CLUSTER")
}

variable "vsphere_datastore" {
  type    = string
  default = env("GOVC_DATASTORE")
}

variable "vsphere_folder" {
  type    = string
  default = env("VSPHERE_TEMPLATE_FOLDER")
}

variable "vsphere_network" {
  type    = string
  default = env("VSPHERE_VLAN")
}

source "vsphere-iso" "debian-amd64" {
  vm_name        = "debian-${var.version}-amd64"
  http_directory = "."
  guest_os_type  = "debian12_64Guest"
  storage {
    disk_size             = var.disk_size
    disk_thin_provisioned = true
  }
  disk_controller_type = ["pvscsi"]
  vcenter_server       = var.vsphere_host
  username             = var.vsphere_username
  password             = var.vsphere_password
  insecure_connection  = true
  datacenter           = var.vsphere_datacenter
  cluster              = var.vsphere_cluster
  host                 = var.vsphere_esxi_host
  folder               = var.vsphere_folder
  datastore            = var.vsphere_datastore
  network_adapters {
    network      = var.vsphere_network
    network_card = "vmxnet3"
  }
  convert_to_template = true
  RAM                 = 2 * 1024
  CPUs                = 4
  iso_paths = [
    var.vsphere_iso_url,
  ]
  ssh_username = "vagrant"
  ssh_password = "vagrant"
  boot_wait    = "15s"
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
    " url={{.HTTPIP}}:{{.HTTPPort}}/tmp/preseed-vsphere.txt",
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
    "source.vsphere-iso.debian-amd64",
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
