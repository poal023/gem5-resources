# arm-parsec

Ubuntu 24.04 arm64 disk image with the 13 PARSEC apps built natively (config
`gcc-hooks-gem5-fs`), `gem5-bridge`/`libm5`, and a matching kernel.
Shared scripts live in `../parsec-common`; the x86 twin is `../x86-parsec`.

## Build
Run on an arm64 node with **LSE** (`grep -w atomics /proc/cpuinfo`): raytrace
uses `ldaddal` and would SIGILL on ARMv8.0 hosts. Needs `qemu-system-arm`,
`qemu-efi-aarch64`, KVM, `unzip`, and kernel build deps (`build-essential flex
bison bc libssl-dev libelf-dev`).

    ./build.sh                 # USE_KVM=false uses TCG with -cpu max

`build-kernel.sh` (run by `build.sh` if needed) builds mainline 6.8.12
`defconfig` plus `gem5_bridge.ko` into `kernel/`. If that kernel fails to boot
in gem5, fall back to Ubuntu's 6.8.0 source as upstream does.

Outputs `disk-image/arm-parsec` (raw) and `kernel/vmlinux-arm-parsec`.
Root is `/dev/vda2`. gem5 must use a release with FEAT_LSE
(`ArmDefaultRelease` or `Armv81`; plain `Armv8` lacks it).
Disk knobs: root size in `http/user-data` (bytes) and `disk_size` in the
`.pkr.hcl` (MiB, root + 566).

## Run
Same `readfile` flow and exit-event order as `../x86-parsec/README.md`
(hypercall 1, 2, 1999, 2000, 3). The bridge page is at `0x10010000`
(`VExpress_GEM5_Foundation`).
