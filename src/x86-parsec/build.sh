#!/bin/bash
set -eu
cd "$(dirname "$0")"
source ../parsec-common/build-common.sh

fetch_packer
stage_sources
./packer init x86-parsec.pkr.hcl
./packer build -var "use_kvm=${USE_KVM:-true}" x86-parsec.pkr.hcl
