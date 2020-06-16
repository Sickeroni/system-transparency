#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

failed="\e[1;5;31mfailed\e[0m"

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../../" && pwd)"


lnxbt_kernel="${dir}/stboot.efi"
lnxbt_kernel_backup="${dir}/stboot.efi.backup"
kernel_src="https://cdn.kernel.org/pub/linux/kernel/v5.x"
kernel_ver="linux-5.4.45"
kernel_config="${dir}/stboot_linuxboot_efistub.defconfig"
kernel_config_mod="${dir}/stboot_linuxboot_efistub.defconfig.modified"
src="${root}/src/kernel"
dev_keys="torvalds@kernel.org gregkh@kernel.org"

user_name="$1"

if ! id "${user_name}" >/dev/null 2>&1
then
   echo "User ${user_name} does not exist"
   exit 1
fi

if [ -f "${lnxbt_kernel}" ]; then
    while true; do
       echo "Current Linuxboot kernel:"
       ls -l "$(realpath --relative-to=${root} ${lnxbt_kernel})"
       read -rp "Recompile? (y/n)" yn
       case $yn in
          [Yy]* ) echo "[INFO]: backup existing kernel to $(realpath --relative-to=${root} ${lnxbt_kernel_backup})"; mv "${lnxbt_kernel}" "${lnxbt_kernel_backup}"; break;;
          [Nn]* ) exit;;
          * ) echo "Please answer yes or no.";;
       esac
    done
fi


if [ -d ${src} ]; then
    echo "[INFO]: Using cached sources in $(realpath --relative-to=${root} ${src})"
else
    echo "[INFO]: Downloading Linux Kernel source files and signature"
    wget "${kernel_src}/${kernel_ver}.tar.xz" -P "${src}" || { rm -rf "${src}"; echo -e "Downloading source files $failed"; exit 1; }
    wget "${kernel_src}/${kernel_ver}.tar.sign" -P "${src}" || { rm -rf "${src}"; echo -e "Downloading signature $failed"; exit 1; }

    mkdir "${src}/gnupg"
    echo "[INFO]: Fetching kernel developer keys"
    if ! gpg --batch --quiet --homedir "${src}/gnupg" --auto-key-locate wkd --locate-keys ${dev_keys}; then
        echo -e "Fetching keys $failed"
        rm -rf "${src}"
        exit 1
    fi
    keyring=${src}/gnupg/keyring.gpg
    gpg --batch --homedir "${src}/gnupg" --no-default-keyring --export ${dev_keys} > "${keyring}"

    echo "[INFO]: Verifying signature of the kernel tarball"
    count=$(xz -cd "${src}/${kernel_ver}.tar.xz" \
            | gpgv --homedir "${src}/gnupg" "--keyring=${keyring}" --status-fd=1 "${src}/${kernel_ver}.tar.sign" - \
            | grep -c -E '^\[GNUPG:\] (GOODSIG|VALIDSIG)')
    if [[ "${count}" -lt 2 ]]; then
        echo -e "Verifying kernel tarball $failed"
        rm -rf "${src}"
        exit 1
    fi

    echo
    echo "[INFO]: Successfully downloaded and verified kernel"
    echo "[INFO]: Build Linuxboot kernel"

    tar -xf "${src}/${kernel_ver}.tar.xz" -C "${src}" || { rm -rf "${src}"; echo -e "Unpacking $failed"; exit 1; }
    chown -R "${user_name}" "${src}"
fi

[ -f "${kernel_config}" ] || { rm -rf "${src}"; echo -e "Finding $kernel_config $failed"; exit 1; }
cp "${kernel_config}" "${src}/${kernel_ver}/.config"
cd "${src}/${kernel_ver}"
while true; do
    echo "Load  $(realpath --relative-to=${root} ${kernel_config}) as .config:"
    echo "It is recommended to just save&exit in the upcoming menu."
    read -rp "Press any key to continue" x
    case $x in
       * ) break;;
    esac
done

make menuconfig
make savedefconfig
cp defconfig "${kernel_config_mod}"
make "-j$(nproc)" || { rm -rf "${src}"; echo -e "Compiling kernel $failed"; exit 1; }
cd "${dir}"
cp "${src}/${kernel_ver}/arch/x86/boot/bzImage" "$lnxbt_kernel"

echo ""
chown -c "${user_name}" "${lnxbt_kernel}"
[ -f "${lnxbt_kernel_backup}" ] && chown -c "${user_name}" "${lnxbt_kernel_backup}"
chown -c "${user_name}" "${kernel_config}"
chown -c "${user_name}" "${kernel_config_mod}"

echo ""
echo "Successfully created $(realpath --relative-to=${root} $lnxbt_kernel) ($kernel_ver)"
echo "Any config changes you may have made via menuconfig are saved to:"
echo "$(realpath --relative-to=${root} ${kernel_config_mod})"
