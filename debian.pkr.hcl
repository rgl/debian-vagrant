packer {
  required_plugins {
    # see https://github.com/hashicorp/packer-plugin-qemu
    qemu = {
      version = "1.0.9"
      source  = "github.com/hashicorp/qemu"
    }
    # see https://github.com/hashicorp/packer-plugin-proxmox
    proxmox = {
      version = "1.1.3"
      source  = "github.com/hashicorp/proxmox"
    }
    # see https://github.com/hashicorp/packer-plugin-virtualbox
    virtualbox = {
      version = "1.0.4"
      source  = "github.com/hashicorp/virtualbox"
    }
    # see https://github.com/hashicorp/packer-plugin-hyperv
    hyperv = {
      version = "1.1.0"
      source  = "github.com/hashicorp/hyperv"
    }
  }
}

variable "headless" {
  type    = bool
  default = true
}

variable "version" {
  type = string
}

variable "vagrant_box" {
  type = string
}

variable "disk_size" {
  type    = string
  default = 8 * 1024
}

variable "iso_url" {
  type    = string
  default = "https://cdimage.debian.org/debian-cd/12.1.0/amd64/iso-cd/debian-12.1.0-amd64-netinst.iso"
}

variable "iso_checksum" {
  type    = string
  default = "sha256:9f181ae12b25840a508786b1756c6352a0e58484998669288c4eec2ab16b8559"
}

variable "proxmox_node" {
  type    = string
  default = env("PROXMOX_NODE")
}

variable "qemu_accelerator" {
  type    = string
  default = "kvm"
}

variable "hyperv_switch_name" {
  type    = string
  default = env("HYPERV_SWITCH_NAME")
}

variable "hyperv_vlan_id" {
  type    = string
  default = env("HYPERV_VLAN_ID")
}

source "qemu" "debian-amd64" {
  accelerator  = var.qemu_accelerator
  machine_type = "q35"
  cpus         = 2
  memory       = 2 * 1024
  qemuargs = concat(
    [
      ["-cpu", "host"],
    ],
    !var.headless && var.qemu_accelerator == "hvf" ? [
      ["-display", "cocoa,show-cursor=on"],
      ["-vga", "virtio"],
    ] : []
  )
  headless            = var.headless
  use_default_display = !var.headless && var.qemu_accelerator == "hvf" ? true : false
  net_device          = "virtio-net"
  http_directory      = "."
  format              = "qcow2"
  disk_size           = var.disk_size
  disk_interface      = "virtio-scsi"
  disk_cache          = "unsafe"
  disk_discard        = "unmap"
  iso_url             = var.iso_url
  iso_checksum        = var.iso_checksum
  ssh_username        = "vagrant"
  ssh_password        = "vagrant"
  ssh_timeout         = "60m"
  boot_wait           = "5s"
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
    " BOOT_DEBUG=2",
    " DEBCONF_DEBUG=5",
    "<enter>",
  ]
  shutdown_command = "echo vagrant | sudo -S poweroff"
}

source "qemu" "debian-uefi-amd64" {
  accelerator  = var.qemu_accelerator
  machine_type = "q35"
  efi_boot     = true
  cpus         = 2
  memory       = 2 * 1024
  qemuargs = concat(
    [
      ["-cpu", "host"],
    ],
    !var.headless && var.qemu_accelerator == "hvf" ? [
      ["-display", "cocoa,show-cursor=on"],
      ["-vga", "virtio"],
    ] : []
  )
  headless            = var.headless
  use_default_display = !var.headless && var.qemu_accelerator == "hvf" ? true : false
  net_device          = "virtio-net"
  http_directory      = "."
  format              = "qcow2"
  disk_size           = var.disk_size
  disk_interface      = "virtio-scsi"
  disk_cache          = "unsafe"
  disk_discard        = "unmap"
  iso_url             = var.iso_url
  iso_checksum        = var.iso_checksum
  ssh_username        = "vagrant"
  ssh_password        = "vagrant"
  ssh_timeout         = "60m"
  boot_wait           = "10s"
  boot_command = [
    "c<wait>",
    "linux /install.amd/vmlinuz",
    " auto=true",
    " url={{.HTTPIP}}:{{.HTTPPort}}/preseed.txt",
    " hostname=vagrant",
    " domain=home",
    " net.ifnames=0",
    " BOOT_DEBUG=2",
    " DEBCONF_DEBUG=5",
    "<enter>",
    "initrd /install.amd/initrd.gz<enter>",
    "boot<enter>",
  ]
  shutdown_command = "echo vagrant | sudo -S poweroff"
}

source "proxmox-iso" "debian-amd64" {
  template_name            = "template-debian-${var.version}"
  template_description     = "See https://github.com/rgl/debian-vagrant"
  insecure_skip_tls_verify = true
  node                     = var.proxmox_node
  machine                  = "q35"
  bios                     = "ovmf"
  efi_config {
    efi_storage_pool = "local-lvm"
  }
  cpu_type = "host"
  cores    = 2
  memory   = 2 * 1024
  vga {
    type   = "qxl"
    memory = 16
  }
  network_adapters {
    model  = "virtio"
    bridge = "vmbr0"
  }
  scsi_controller = "virtio-scsi-pci"
  disks {
    type         = "scsi"
    disk_size    = "${var.disk_size}M"
    storage_pool = "local-lvm"
  }
  iso_storage_pool = "local"
  iso_url          = var.iso_url
  iso_checksum     = var.iso_checksum
  unmount_iso      = true
  os               = "l26"
  ssh_username     = "vagrant"
  ssh_password     = "vagrant"
  ssh_timeout      = "60m"
  http_directory   = "."
  boot_wait        = "30s"
  boot_command = [
    "c<wait>",
    "linux /install.amd/vmlinuz",
    " auto=true",
    " url={{.HTTPIP}}:{{.HTTPPort}}/preseed.txt",
    " hostname=vagrant",
    " domain=home",
    " net.ifnames=0",
    " BOOT_DEBUG=2",
    " DEBCONF_DEBUG=5",
    "<enter>",
    "initrd /install.amd/initrd.gz<enter>",
    "boot<enter>"
  ]
}

source "virtualbox-iso" "debian-amd64" {
  guest_os_type        = "Debian_64"
  guest_additions_mode = "upload"
  headless             = var.headless
  http_directory       = "."
  vboxmanage = [
    ["modifyvm", "{{.Name}}", "--memory", "2048"],
    ["modifyvm", "{{.Name}}", "--cpus", "2"],
    ["modifyvm", "{{.Name}}", "--vram", "32"],
    ["modifyvm", "{{.Name}}", "--nictype1", "virtio"],
    ["modifyvm", "{{.Name}}", "--nictype2", "virtio"],
    ["modifyvm", "{{.Name}}", "--nictype3", "virtio"],
    ["modifyvm", "{{.Name}}", "--nictype4", "virtio"],
  ]
  disk_size            = var.disk_size
  hard_drive_interface = "sata"
  hard_drive_discard   = true
  iso_url              = var.iso_url
  iso_checksum         = var.iso_checksum
  ssh_username         = "vagrant"
  ssh_password         = "vagrant"
  ssh_timeout          = "60m"
  boot_wait            = "5s"
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
    " BOOT_DEBUG=2",
    " DEBCONF_DEBUG=5",
    "<enter>"
  ]
  shutdown_command    = "echo vagrant | sudo -S poweroff"
  post_shutdown_delay = "2m"
}

source "hyperv-iso" "debian-amd64" {
  temp_path         = "tmp"
  headless          = var.headless
  http_directory    = "."
  generation        = 2
  cpus              = 2
  memory            = 2 * 1024
  switch_name       = var.hyperv_switch_name
  vlan_id           = var.hyperv_vlan_id
  disk_size         = var.disk_size
  iso_url           = var.iso_url
  iso_checksum      = var.iso_checksum
  ssh_username      = "vagrant"
  ssh_password      = "vagrant"
  ssh_timeout       = "60m"
  first_boot_device = "DVD"
  boot_order        = ["SCSI:0:0"]
  boot_wait         = "5s"
  boot_command = [
    "c<wait>",
    "linux /install.amd/vmlinuz",
    " auto=true",
    " url={{.HTTPIP}}:{{.HTTPPort}}/tmp/preseed-hyperv.txt",
    " hostname=vagrant",
    " domain=home",
    " net.ifnames=0",
    " BOOT_DEBUG=2",
    " DEBCONF_DEBUG=5",
    "<enter>",
    "initrd /install.amd/initrd.gz<enter>",
    "boot<enter>",
  ]
  shutdown_command = "echo vagrant | sudo -S poweroff"
}

build {
  sources = [
    "source.qemu.debian-amd64",
    "source.qemu.debian-uefi-amd64",
    "source.proxmox-iso.debian-amd64",
    "source.virtualbox-iso.debian-amd64",
    "source.hyperv-iso.debian-amd64",
  ]

  provisioner "shell" {
    expect_disconnect = true
    execute_command   = "echo vagrant | sudo -S {{ .Vars }} bash {{ .Path }}"
    scripts = [
      "provision-guest-additions.sh",
      "provision.sh"
    ]
  }

  provisioner "shell-local" {
    environment_vars = [
      "PACKER_VERSION={{packer_version}}",
      "PACKER_VM_NAME={{build `ID`}}",
    ]
    scripts = [
      "provision-local-hyperv.cmd"
    ]
    only = [
      "debian-amd64-hyperv",
    ]
  }

  post-processor "vagrant" {
    only = [
      "qemu.debian-amd64",
      "hyperv-iso.debian-amd64",
      "virtualbox-iso.debian-amd64",
    ]
    output               = var.vagrant_box
    vagrantfile_template = "Vagrantfile.template"
  }

  post-processor "vagrant" {
    only = [
      "qemu.debian-uefi-amd64",
    ]
    output               = var.vagrant_box
    vagrantfile_template = "Vagrantfile-uefi.template"
  }
}
