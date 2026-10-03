packer {
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "~> 1"
    }
  }
}

variable "image_name" {
  type    = string
  default = "x86-parsec"
}

variable "ssh_password" {
  type    = string
  default = "12345"
}

variable "ssh_username" {
  type    = string
  default = "gem5"
}

variable "cpus" {
  type    = string
  default = "16"
}

variable "memory" {
  type    = string
  default = "16384"
}

variable "use_kvm" {
  type    = bool
  default = true
}

source "qemu" "initialize" {
  accelerator      = var.use_kvm ? "kvm" : "tcg"
  boot_command     = ["e<wait>",
                      "<down><down><down>",
                      "<end><bs><bs><bs><bs><wait>",
                      "autoinstall  ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---<wait>",
                      "<f10><wait>"
                    ]
  cpus             = var.cpus
  disk_size        = "24579" # 24 GiB root + 1 MiB bios_grub + 2 MiB offset
  format           = "raw"
  headless         = "true"
  http_directory   = "http"
  iso_checksum     = "sha256:c3514bf0056180d09376462a7a1b4f213c1d6e8ea67fae5c25099c6fd3d8274b"
  iso_urls         = ["https://releases.ubuntu.com/releases/noble/ubuntu-24.04.3-live-server-amd64.iso"]
  memory           = var.memory
  output_directory = "disk-image"
  qemu_binary      = "/usr/bin/qemu-system-x86_64"
  qemuargs         = [["-cpu", var.use_kvm ? "host" : "max"], ["-display", "none"]]
  shutdown_command = "echo '${var.ssh_password}'|sudo -S shutdown -P now"
  ssh_password     = "${var.ssh_password}"
  ssh_username     = "${var.ssh_username}"
  ssh_wait_timeout = "60m"
  vm_name          = "${var.image_name}"
  ssh_handshake_attempts = "1000"
}

build {
  sources = ["source.qemu.initialize"]

  provisioner "file" {
    destination = "/home/gem5/"
    sources = [
      "../parsec-common/files/exit.sh",
      "../parsec-common/files/after_boot.sh",
      "../parsec-common/files/serial-getty@.service",
      "../parsec-common/scripts/add-gem5-bldconfs.sh",
      "files/gem5_init.sh",
      "build/parsec-src.tar.gz",
      "build/gem5-src.tar.gz",
    ]
  }

  provisioner "shell" {
    execute_command   = "echo '${var.ssh_password}' | {{ .Vars }} sudo -E -S bash '{{ .Path }}'"
    environment_vars  = ["ISA=x86"]
    scripts           = ["../parsec-common/scripts/post-installation.sh",
                         "../parsec-common/scripts/install-gem5-bridge.sh"]
  }

  provisioner "shell" {
    environment_vars = ["ISA=x86"]
    scripts          = ["../parsec-common/scripts/install-parsec.sh"]
  }

  provisioner "shell" {
    execute_command = "echo '${var.ssh_password}' | {{ .Vars }} sudo -E -S bash '{{ .Path }}'"
    inline = [
      "/usr/src/linux-headers-$(uname -r)/scripts/extract-vmlinux /boot/vmlinuz-$(uname -r) > /home/gem5/vmlinux-x86-parsec",
      "chown gem5 /home/gem5/vmlinux-x86-parsec",
    ]
  }

  provisioner "file" {
    source      = "/home/gem5/vmlinux-x86-parsec"
    destination = "./disk-image/vmlinux-x86-parsec"
    direction   = "download"
  }

  provisioner "shell" {
    execute_command = "echo '${var.ssh_password}' | {{ .Vars }} sudo -E -S bash '{{ .Path }}'"
    scripts         = ["../parsec-common/scripts/disable-network.sh"]
  }
}
