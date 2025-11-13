#!/bin/bash

# Copyright (c) 2024 Advanced Micro Devices, Inc.
# All rights reserved.
# SPDX-License-Identifier: BSD 3-Clause

echo "Post-boot...\n"
#gem5-bridge hypercall 2
IGNORE_M5=0

: '
cmdline=$(cat /proc/cmdline)
interactive=false
if [[ $cmdline == *"interactive"* ]]; then
    interactive=true
fi
'

# Read script from host and run it
gem5-bridge readfile > script.sh
echo "gem5-bridge readfile on script.sh attempted\n"
if [ -s script.sh ]; then
    # if the file is not empty, execute it and exit
    echo "Executing script.sh\n" 
    chmod +x script.sh
    ./script.sh
    #gem5-bridge hypercall 3
    m5 exit
fi
