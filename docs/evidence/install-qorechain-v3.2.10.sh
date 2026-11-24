#!/usr/bin/env bash
set -euo pipefail

install_dir="${HOME}/.local/qorechain/v3.2.10"
repo_dir="/mnt/c/Users/Hari Ram/Documents/chronoquota"
archive="${install_dir}/qorechaind-v3.2.10-final-r2-linux-amd64.tar.gz"
expected_sha256="05bf891db98538dce1d9a710f93e5102c0e9ace79f57b4cbf10ae688c63fecb4"
expected_size=111890694

actual_sha256="$(sha256sum "$archive" | awk '{print $1}')"
actual_size="$(stat -c '%s' "$archive")"
[[ "$actual_sha256" == "$expected_sha256" ]] || { echo 'SHA-256 mismatch; refusing extraction.' >&2; exit 3; }
[[ "$actual_size" == "$expected_size" ]] || { echo 'Size mismatch; refusing extraction.' >&2; exit 4; }
[[ ! -e "${install_dir}/qorechaind" && ! -e "${install_dir}/lib" ]] || {
  echo 'Refusing to overwrite extracted files.' >&2
  exit 5
}

tar -xzf "$archive" -C "$install_dir"

cat > "${install_dir}/env.sh" <<'ENV'
qorechain_install_dir="${HOME}/.local/qorechain/v3.2.10"
case ":${LD_LIBRARY_PATH:-}:" in
  *":${qorechain_install_dir}/lib:"*) ;;
  *) export LD_LIBRARY_PATH="${qorechain_install_dir}/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}" ;;
esac
case ":${PATH:-}:" in
  *":${qorechain_install_dir}:"*) ;;
  *) export PATH="${qorechain_install_dir}${PATH:+:${PATH}}" ;;
esac
ENV

chmod 0644 "${install_dir}/env.sh"
{
  printf 'Install directory: %s\n' "$install_dir"
  printf 'Archive SHA-256: %s\n' "$actual_sha256"
  printf 'Archive bytes: %s\n' "$actual_size"
  printf 'Extraction UTC: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf 'Environment setup: source %s/env.sh\n' "$install_dir"
} | tee "${install_dir}/install-metadata.txt" "${repo_dir}/docs/evidence/qorechain-v3.2.10-install-metadata.txt"

printf 'Extracted files:\n'
find "$install_dir" -maxdepth 2 -type f -printf '%P\n' | sort
