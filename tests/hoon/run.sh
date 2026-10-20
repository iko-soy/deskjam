#!/usr/bin/env bash
# run.sh - run the Hoon unit tests with `urbit eval`, without a ship.
#
#   tests/hoon/run.sh [NAME ...]     e.g. tests/hoon/run.sh deskjam-url
#
# tests/hoon/NAME.hoon tests desk/lib/NAME.hoon (default: all of them).
# urbit eval has the standard library and zuse in its subject, so it can
# build libraries without Ford runes (/-, /+). It reads
#
#   =>  <desk/lib/NAME.hoon>
#   <desk-bill, sys-kelvin and desk-docket: the desk's own files, as cords>
#   <tests/hoon/NAME.hoon>
#
# so the checks see the library's arms. urbit eval exits 0 even when the
# Hoon crashes, so a test passes when its output has %tests-passed.
#
# Needs `urbit` (vere) on PATH, or URBIT=/path/to/urbit; from the repo,
# `nix shell --inputs-from . nixpkgs#urbit -c tests/hoon/run.sh` gets it.
# DESK=DIR tests another copy of the desk. `nix flake check` runs this
# with nixpkgs' urbit, and so does
# `nix build -L .#checks.x86_64-linux.hoon-tests`.
set -euo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
desk=${DESK:-$here/../../desk}
urbit=${URBIT:-urbit}
command -v "$urbit" >/dev/null || { echo "run.sh: no $urbit; put urbit on PATH, or set URBIT" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# a file's text as a cord, in a ''' block (no escapes), so it must not
# hold a line that is just '''
cord() {  # face file
  if grep -qx "'''" "$2"; then
    echo "run.sh: $2 has a line ''', which can't go in a ''' block" >&2
    exit 1
  fi
  printf '=/  %s=@t\n'"'''"'\n%s\n'"'''"'\n' "$1" "$(cat "$2")"
}

if [[ $# -eq 0 ]]; then
  set -- "$here"/*.hoon
fi
failed=0
for t in "$@"; do
  name=$(basename "$t" .hoon)
  lib=$desk/lib/$name.hoon
  [[ -f $lib ]] || { echo "run.sh: no library $lib for $here/$name.hoon" >&2; exit 1; }
  {
    echo '=>'
    cat "$lib"
    echo
    cord desk-bill "$desk/desk.bill"
    cord sys-kelvin "$desk/sys.kelvin"
    cord desk-docket "$desk/desk.docket-0"
    cat "$here/$name.hoon"
  } > "$tmp/$name.hoon"
  "$urbit" eval < "$tmp/$name.hoon" > "$tmp/$name.log" 2>&1 || true
  checks=$(grep -c '^?>' "$here/$name.hoon" || true)
  if grep -q '%tests-passed' "$tmp/$name.log"; then
    echo "$name: $checks checks passed"
  else
    echo "$name: FAILED. urbit eval printed (a failing check's label comes last):"
    tr -d '\r' < "$tmp/$name.log"
    failed=1
  fi
done
exit "$failed"
