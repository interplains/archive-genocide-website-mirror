#!/bin/sh
# Shared signature verification, bound to the project's key. Sourced by verify.sh and get-data.sh
# so there is ONE implementation of this and it cannot drift between them.
#
#   verify_signed FILE FILE.asc KEYFILE PINNED_FPR_NOSPACE
#     -> 0 when FILE.asc is a good signature over FILE made by the pinned key
#     -> 1 otherwise, having said why
#
# WHY IT IS WRITTEN THIS WAY. The previous check did three things wrong, and a real GnuPG
# reproduction on 2026-09-17 showed they combined into a working forgery:
#
#   * it read only the FIRST fingerprint in the key file
#   * it ran `gpg --import`, putting every key in that file into the user's own keyring
#   * it accepted any output containing the words "Good signature", never asking whose
#
# So a key file holding the genuine key followed by an attacker's key passed the fingerprint
# check, imported both, and a manifest signed by the attacker produced "Good signature" -- the
# script reported the data authentic. An attacker key already present in the user's keyring did
# the same thing with no second key in the file at all.
#
# Three properties close it, and all three are required:
#   1. an ISOLATED keyring, so the user's own keyring cannot vouch for anything and nothing is
#      imported into it;
#   2. --status-fd, so the decision rests on GnuPG's machine-readable VALIDSIG line and not on
#      human text that changes with the user's locale;
#   3. the signer's PRIMARY fingerprint must equal the pinned one. VALIDSIG carries the signing
#      key in field 2 and the primary in the last field, so a legitimate signing SUBKEY of the
#      project key still verifies while a different key never does.

verify_signed() {
  vs_file="$1"; vs_sig="$2"; vs_key="$3"; vs_fpr="$4"
  command -v gpg >/dev/null 2>&1 || { echo "   gpg not installed"; return 1; }
  [ -s "$vs_file" ] || { echo "   missing $vs_file"; return 1; }
  [ -s "$vs_sig" ]  || { echo "   missing $vs_sig"; return 1; }
  [ -s "$vs_key" ]  || { echo "   missing $vs_key"; return 1; }

  # Every key in the file must be the pinned one. A genuine key bundled with an extra key is
  # precisely the attack above, so it is refused rather than tolerated.
  vs_n=$(gpg --batch --with-colons --show-keys "$vs_key" 2>/dev/null | grep -c '^fpr:')
  vs_bad=$(gpg --batch --with-colons --show-keys "$vs_key" 2>/dev/null \
           | awk -F: '/^fpr:/{print $10}' | grep -vx "$vs_fpr" | wc -l | tr -d ' ')
  if [ "${vs_n:-0}" -eq 0 ]; then
    echo "   key file contains no OpenPGP key"; return 1
  fi
  if [ "${vs_bad:-1}" -ne 0 ]; then
    echo "   key file contains $vs_bad key(s) that are NOT the project's key -- refusing it"
    return 1
  fi

  vs_home=$(mktemp -d 2>/dev/null || mktemp -d -t agverify) || return 1
  chmod 700 "$vs_home"
  gpg --batch --no-options --no-default-keyring --homedir "$vs_home" \
      --quiet --import "$vs_key" 2>/dev/null
  vs_status="$vs_home/status"
  gpg --batch --no-options --no-default-keyring --homedir "$vs_home" \
      --status-fd 3 --verify "$vs_sig" "$vs_file" 3>"$vs_status" >/dev/null 2>&1 || true
  vs_signer=$(awk '/^\[GNUPG:\] VALIDSIG /{print $NF; exit}' "$vs_status" 2>/dev/null)
  rm -rf "$vs_home"

  if [ -z "$vs_signer" ]; then
    echo "   no valid signature"; return 1
  fi
  if [ "$vs_signer" != "$vs_fpr" ]; then
    echo "   signed by $vs_signer, expected $vs_fpr -- WRONG KEY"; return 1
  fi
  return 0
}
