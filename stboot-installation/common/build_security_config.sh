#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../../" && pwd)"

# import global configuration
source ${root}/run.config

out="${root}/out/stboot-installation"
name="security_configuration.json"
security_config="${out}/${name}"
fingerprint_file=${ST_BOOT_COMMON_ROOTCERT_FINGERPRINT_FILE}
num_signatures=${ST_BOOT_COMMON_NUM_SIGNATURES}
boot_mode=${ST_BOOT_COMMON_BOOT_MODE}

if [ ! -d "${out}" ]; then mkdir -p "${out}"; fi

echo
echo "[INFO]: Creating $(realpath --relative-to="${root}" "${security_config}")"

cat >"${security_config}" <<EOL
{
  "minimal_signatures_match": ${num_signatures},
  "fingerprints": [
    "$(cut -d' ' -f1 "${fingerprint_file}")"
  ],
  "boot_mode": "${boot_mode}"
}
EOL

cat "$(realpath --relative-to="${root}" "${security_config}")"

