#! /bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

failed="\e[1;5;31mfailed\e[0m"

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="${dir}"

# Source script with environment checks.
checks=${root}/scripts/checks.sh
[ -r ${checks} ] && source ${checks}

echo ""
echo "Checking dependencies ..."
checkGCC
checkGO
checkMISC

echo ""
echo "Checking environment ..."
checkDebootstrap

# Global build configuration
global_config=${root}/run.config

if [ ! -r ${global_config} ]; then
   bash "${root}/scripts/make_global_config.sh"
fi
source ${global_config}


echo
echo "############################################################"
echo " Install toolchain"
echo "############################################################"
echo
while true; do
   echo "Run  (r)"
   echo "Skip (s)"
   echo "Quit (q)"
   read -rp ">> " x
   case $x in
      [Rr]* ) bash "${root}/scripts/make_toolchain.sh"; break;;
      [Ss]* ) break;;
      [Qq]* ) exit;;
      * ) echo "Invalid input";;
   esac
done

echo
echo "############################################################"
echo " Generate example keys and certificates"
echo "############################################################"
echo
while true; do
   echo "Run  (r)"
   echo "Skip (s)"
   echo "Quit (q)"
   read -rp ">> " x
   case $x in
      [Rr]* ) bash "${root}/scripts/make_keys_and_certs.sh"; break;;
      [Ss]* ) break;;
      [Qq]* ) exit;;
      * ) echo "Invalid input";;
   esac
done

echo
echo "############################################################"
echo " Create default stboot data files"
echo "############################################################"
echo
while true; do
   echo "Run  (r)"
   echo "Skip (s)"
   echo "Quit (q)"
   read -rp ">> " x
   case $x in
      [Rr]* ) bash "${root}/scripts/make_example_data.sh"; break;;
      [Ss]* ) break;;
      [Qq]* ) exit;;
      * ) echo "Invalid input";;
   esac
done

echo
echo "############################################################"
echo " Build bootloader "
echo "############################################################"
echo
while true; do
   echo "Run  (1) Coreboot ROM"
   echo "Run  (2) Image for UEFI systems"
   echo "Run  (3) Image for mixed-firmware systems"
   echo "Skip (s)"
   echo "Quit (q)"
   read -rp ">> " x
   case $x in
      [1]* ) bash "${root}/stboot/coreboot-firmware/make_dummy.sh"; break;;
      [2]* ) bash "${root}/stboot/uefi-firmware/make_bootloader.sh"; break;;
      [3]* ) bash "${root}/stboot/mixed-firmware/make_image.sh" "$(id -un)"; break;;
      [Ss]* ) break;;
      [Qq]* ) exit;;
      * ) echo "Invalid input";;
   esac
done

echo
echo "############################################################"
echo " Setup OS boot configuration (Root privileges required)"
echo "############################################################"
echo
while true; do
   echo "Run  (r) Reproducible Debian Buster"
   echo "Skip (s)"
   echo "Quit (q)"
   read -rp ">> " x
   case $x in
      [Rr]* ) bash "${root}/operating-system/debian/make_stconfig.sh"; break;;
      [Ss]* ) break;;
      [Qq]* ) exit;;
      * ) echo "Invalid input";;
   esac
done

echo
echo "############################################################"
echo " Use stconfig tool with example keys to create and sign a"
echo " ST-bootball for Debian Buster"
echo "############################################################"
echo
stconfig="${root}/configs/debian-buster-amd64/stconfig.json"
while true; do
   echo "configuration: $(realpath --relative-to=${root} ${stconfig})"
   cat ${stconfig}
   echo ""
   echo "Run  (r) with configuration"
   echo "Skip (s)"
   echo "Quit (q)"
   read -rp ">> " x
   case $x in
      [Rr]* ) bash "${root}/scripts/create_and_sign_bootball.sh" "${stconfig}"; break;;
      [Ss]* ) break;;
      [Qq]* ) exit;;
      * ) echo "Invalid input";;
   esac
done

echo
echo "############################################################"
echo " Upload bootball to provisioning server"
echo "############################################################"
echo
bootball_pattern="stboot.ball*"
dir=$(dirname "${stconfig}")
files=( ${dir}/$bootball_pattern )
[ "${#files[@]}" -gt "1" ] && { echo -e "upload $failed : more then one bootbool files in $(dirname "${dir}")"; exit 1; }
bootball=${files[0]}
while true; do
   echo "bootball: $(realpath --relative-to=${root} ${bootball})"
   echo "Run  (r) with bootball"
   echo "Skip (s)"
   echo "Quit (q)"
   read -rp ">> " x
   case $x in
      [Rr]* ) bash "${root}/scripts/upload_bootball.sh" "${bootball}"; break;;
      [Ss]* ) break;;
      [Qq]* ) exit;;
      * ) echo "Invalid input";;
   esac
done


echo
echo "############################################################"
echo " Run in QEMU "
echo "############################################################"
echo
while true; do
   echo "Run  (1) Coreboot ROM"
   echo "Run  (2) Image for UEFI systems"
   echo "Run  (3) Image for mixed-firmware systems"
   echo "Skip (s)"
   echo "Quit (q)"
   read -rp ">> " x
   case $x in
      [1]* ) bash "${root}/scripts/start_qemu_coreboot-firmware.sh"; break;;
      [2]* ) bash "${root}/scripts/start_qemu_uefi-firmware.sh"; break;;
      [3]* ) bash "${root}/scripts/start_qemu_mixed-firmware.sh"; break;;
      [Ss]* ) break;;
      [Qq]* ) exit;;
      * ) echo "Invalid input";;
   esac
done
