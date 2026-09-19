# Verify a staged metadata download on Windows.
#
#   powershell -ExecutionPolicy Bypass -File verify-data.ps1 -Stage data\.new -Key key.asc
#
# Exit 0 = verified (or hashes verified with the signature explicitly reported as UNCHECKED)
# Exit 1 = reject the download
#
# WHY THIS EXISTS. get-data.cmd downloaded the four metadata files and reported "data ready" as
# soon as curl succeeded -- it never fetched SHA256SUMS-data, never checked a hash and never
# checked a signature. The launcher verifies the separate TORRENT release, which is a different
# thing, so the standard Windows path authenticated the descriptions, dates, classifications and
# source links not at all, even with GPG installed. Those fields are what research depends on.
#
# Where gpg exists, the signature is bound to the pinned key the same way verify-sig.sh does it:
# an isolated keyring, GnuPG's machine-readable status output, and a check that the signer's
# PRIMARY fingerprint is the pinned one. Where gpg is absent this verifies hashes only and says
# so in those words -- a silent downgrade is how the Unix side went wrong for six days.
param(
  [Parameter(Mandatory=$true)][string]$Stage,
  [string]$Key = 'key.asc',
  [string]$Fpr = 'C24EC92B12D6670A2516065F9B4D575499AFA53C'
)
$ErrorActionPreference = 'Stop'
$manifest = Join-Path $Stage 'SHA256SUMS-data'
$sig      = Join-Path $Stage 'SHA256SUMS-data.asc'

if (-not (Test-Path $manifest)) {
  # FAIL CLOSED. This used to print "UNVERIFIED" and exit 0, so get-data.cmd's errorlevel check
  # passed and the downloader told the user the data was "ready and verified" -- for data nothing
  # had verified. That is the same fail-open defect the September audit found in verify.sh, where
  # a missing or empty manifest printed "Authentic" having checked nothing. A verifier that cannot
  # verify must not return success; on an archive whose whole claim is that it can be checked,
  # a false "verified" is worse than a loud failure.
  Write-Host "  [FAIL] no signed data manifest (SHA256SUMS-data) was published or downloaded."
  Write-Host "         The metadata has NOT been verified."
  if ($env:ALLOW_UNVERIFIED -eq '1') {
    Write-Host "         ALLOW_UNVERIFIED=1 set - continuing anyway, at your own risk."
    exit 0
  }
  Write-Host "         To use the data anyway, set ALLOW_UNVERIFIED=1 and re-run."
  exit 1
}

# ---- signature, when gpg is available ----------------------------------------------------
$gpg = Get-Command gpg -ErrorAction SilentlyContinue
if ($gpg -and (Test-Path $sig) -and (Test-Path $Key)) {
  $fprs = @(& gpg --batch --with-colons --show-keys $Key 2>$null |
            Where-Object { $_ -like 'fpr:*' } |
            ForEach-Object { ($_ -split ':')[9] })
  if ($fprs.Count -eq 0) { Write-Host "  [FAIL] $Key contains no OpenPGP key."; exit 1 }
  $bad = @($fprs | Where-Object { $_ -ne $Fpr })
  if ($bad.Count -gt 0) {
    Write-Host "  [FAIL] $Key contains $($bad.Count) key(s) that are NOT the archive's key."
    Write-Host "         A genuine key bundled with another is how a forged manifest is accepted."
    exit 1
  }
  $home2 = Join-Path ([IO.Path]::GetTempPath()) ("agv_" + [guid]::NewGuid().ToString('N'))
  New-Item -ItemType Directory -Path $home2 -Force | Out-Null
  try {
    & gpg --batch --no-options --no-default-keyring --homedir $home2 --quiet --import $Key 2>$null
    $status = Join-Path $home2 'status.txt'
    & gpg --batch --no-options --no-default-keyring --homedir $home2 `
          --status-file $status --verify $sig $manifest 2>$null | Out-Null
    $signer = $null
    if (Test-Path $status) {
      $line = Select-String -Path $status -Pattern '^\[GNUPG:\] VALIDSIG ' | Select-Object -First 1
      if ($line) { $parts = ($line.Line -split '\s+'); $signer = $parts[$parts.Length - 1] }
    }
    if (-not $signer)      { Write-Host "  [FAIL] no valid signature on the data manifest."; exit 1 }
    if ($signer -ne $Fpr)  { Write-Host "  [FAIL] manifest signed by $signer, expected $Fpr - WRONG KEY."; exit 1 }
    Write-Host "  signature OK (signed by the archive's key)"
  } finally {
    Remove-Item -Recurse -Force $home2 -ErrorAction SilentlyContinue
  }
} else {
  Write-Host "  NOTE: gpg not available - hashes will be checked but the SIGNATURE IS NOT VERIFIED."
}

# ---- hashes, always ----------------------------------------------------------------------
$bad = 0; $checked = 0
foreach ($line in Get-Content $manifest) {
  if ($line -notmatch '^\s*([0-9a-fA-F]{64})\s+\*?(.+?)\s*$') { continue }
  $want = $Matches[1].ToLower(); $name = $Matches[2]
  $path = Join-Path $Stage $name
  if (-not (Test-Path $path)) { Write-Host "  [FAIL] $name : missing"; $bad++; continue }
  $got = (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash.ToLower()
  $checked++
  if ($got -ne $want) { Write-Host "  [FAIL] $name : hash mismatch"; $bad++ }
}
if ($checked -eq 0) {
  Write-Host "  [FAIL] the manifest verified nothing - it is empty or malformed."
  exit 1
}
if ($bad -gt 0) {
  Write-Host "  [FAIL] $bad of $checked file(s) do not match the signed hashes."
  exit 1
}
Write-Host "  $checked file(s) match the signed hashes."
exit 0
