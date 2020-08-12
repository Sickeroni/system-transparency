#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../../" && pwd)"

# import global configuration
source ${root}/run.config

out="${dir}/stboot.efi"
kernel_version=${ST_UEFI_FIRMWARE_EFISTUB_KERNEL_VERSION}
kernel_config=${ST_UEFI_FIRMWARE_EFISTUB_KERNEL_CONFIG}
cmdline=${ST_LINUXBOOT_CMDLINE}


if [[ "${root}/stboot/initramfs-linuxboot.cpio.gz" -nt "${out}" ]]; then
   # Force rebuild as initrd changed. FIXME: Use makefile
   rm "${out}"
fi

echo "[INFO]: Patching kernel configuration to include configured command line:"
echo "[INFO]: cmdline: ${cmdline}"

cp "${kernel_config}" "${kernel_config}.patch"
sed -i "s/CONFIG_CMDLINE=.*/CONFIG_CMDLINE=\"${cmdline}\"/" "${kernel_config}.patch"

echo "[INFO]: $(realpath --relative-to="${root}" "${kernel_config}.patch" created.)"

bash "${root}/stboot/make_kernel.sh" "${kernel_config}" "${out}" "${kernel_version}"

trap - EXIT
