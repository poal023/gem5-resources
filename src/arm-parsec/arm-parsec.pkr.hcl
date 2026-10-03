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
  default = "arm-parsec"
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
  boot_command     = [
                      "c<wait>",
                      "linux /casper/vmlinuz autoinstall ds=nocloud-net\\;s=http://{{.HTTPIP}}:{{.HTTPPort}}/ --- ",
                      "<enter><wait>",
                      "initrd /casper/initrd",
                      "<enter><wait>",
                      "boot",
                      "<enter>",
                      "<wait>"
                      ]
  cpus             = var.cpus
  disk_size        = "25142" # 24 GiB root + 538 MiB ESP + ~4 MiB GPT overhead
  format           = "raw"
  headless         = "true"
  http_directory   = "http"
  iso_checksum     = "sha256:d2d9986ada3864666e36a57634dfc97d17ad921fa44c56eeaca801e7dab08ad7"
  iso_urls         = ["https://cdimage.ubuntu.com/releases/24.04/release/ubuntu-24.04-live-server-arm64.iso"]
  memory           = var.memory
  output_directory = "disk-image"
  qemu_binary      = "/usr/bin/qemu-system-aarch64"
  # raytrace needs LSE atomics: "max" under TCG, the host CPU under KVM.
  qemuargs         = [["-boot", "order=dc"],
                      ["-bios", "./files/flash0.img"],
                      ["-cpu", var.use_kvm ? "host" : "max"],
                      ["-machine", "virt,gic-version=3,accel=${var.use_kvm ? "kvm" : "tcg"}"],
                      ["-device", "virtio-gpu-pci"],
                      ["-device", "qemu-xhci"],
                      ["-device", "usb-kbd"]]
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
      "kernel/modules",
    ]
  }

  provisioner "shell" {
    execute_command  = "echo '${var.ssh_password}' | {{ .Vars }} sudo -E -S bash '{{ .Path }}'"
    environment_vars = ["ISA=arm64"]
    scripts          = ["../parsec-common/scripts/post-installation.sh",
                        "../parsec-common/scripts/install-gem5-bridge.sh"]
  }

  provisioner "shell" {
    environment_vars = ["ISA=arm64"]
    scripts          = ["../parsec-common/scripts/install-parsec.sh"]
  }

  provisioner "shell" {
    execute_command = "echo '${var.ssh_password}' | {{ .Vars }} sudo -E -S bash '{{ .Path }}'"
    scripts         = ["../parsec-common/scripts/disable-network.sh"]
  }
}
