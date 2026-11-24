# Windows entry point for the local QoreLease Phase 1E demonstration.
# Requires Ubuntu WSL2 with Foundry installed at ~/.foundry/bin and Node >= 22.6.
param([switch]$SaveEvidence)

$ErrorActionPreference = "Continue"
$root = Split-Path -Parent $PSScriptRoot
$log = Join-Path $root "docs/evidence/local-e2e.log"

wsl -d Ubuntu -- bash "/mnt/c/Users/Hari Ram/Documents/chronoquota/scripts/local-e2e.sh" 2>&1 | Tee-Object -Variable output
$code = $LASTEXITCODE
if ($SaveEvidence) {
  $output | Out-File -FilePath $log -Encoding utf8
}
if ($code -ne 0) { exit $code }
