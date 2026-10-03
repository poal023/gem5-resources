# x86-parsec

Ubuntu 24.04 disk image with the 13 PARSEC apps built natively (config
`gcc-hooks-gem5-fs`) and `gem5-bridge`/`libm5`. Shared scripts live in
`../parsec-common`; the ARM twin is `../arm-parsec`.

## Build
Host needs `qemu-system-x86`, KVM and `unzip`.

    ./build.sh                 # USE_KVM=false for TCG; PARSEC_ROOT/GEM5_SRC override sources

Outputs `disk-image/x86-parsec` (raw) and `disk-image/vmlinux-x86-parsec`.
The kernel is the distro kernel's extracted `vmlinux`; `gem5_bridge.ko` is
built against it in the guest. Root is partition 2 (`root=/dev/sda2` in gem5).
Resize the root partition in `http/user-data` (bytes) and `disk_size` in the
`.pkr.hcl` (MiB, root + 3) together.

## Run
Pass the command through `readfile`, e.g.
`cd /home/gem5/parsec-benchmark; source env.sh; parsecmgmt -a run -p blackscholes -c gcc-hooks-gem5-fs -i simsmall -n 1`.
Exit events arrive in order: hypercall 1 (init), 2 (after_boot), 1999 (ROI
begin), 2000 (ROI end), 3 (script done).

Boot with `init=/sbin/init.old interactive` to debug in QEMU.

`files/gem5_init.sh` and `../parsec-common/files/after_boot.sh` are adapted
from the local x86-ubuntu files to follow upstream
`ubuntu-generic-diskimages` (hypercall 1/2/3, `modprobe gem5_bridge`); diff
them against upstream `stable` before relying on them.
