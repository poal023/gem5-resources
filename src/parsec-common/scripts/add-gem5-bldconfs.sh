#!/bin/bash
# Usage: add-gem5-bldconfs.sh <parsec-root>
# Gives every package a gcc-hooks-gem5 and gcc-hooks-gem5-fs bldconf that
# chains to its gcc-hooks one. Existing files are never overwritten.
set -eu

root="$1"

write_if_missing() {
    [ -e "$1" ] || printf '#!/bin/bash\n\nsource ${PARSECDIR}/%s\n' "$2" > "$1"
}

for hooks in "$root"/pkgs/*/*/parsec/gcc-hooks.bldconf; do
    dir=$(dirname "$hooks")
    rel=${dir#"$root"/}
    write_if_missing "$dir/gcc-hooks-gem5.bldconf" "$rel/gcc-hooks.bldconf"
    write_if_missing "$dir/gcc-hooks-gem5-fs.bldconf" "$rel/gcc-hooks-gem5.bldconf"
done
