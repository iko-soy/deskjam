#!/usr/bin/env bash
# sync-deskjam.sh - build the %deskjam desk with Nix, copy it to $DIST
# (writable: Nix builds are read-only) and commit it to the fakezod's
# %deskjam desk with sync-desk.sh, printing what the ship logged.
#
#   sync-deskjam.sh [-F FLAKE | -d DIR] [-v] [-q SECS] [-m SECS]
#
#   (default) the repo's working copy: nix build $REPO#desk. Nix only
#             sees files git knows about, so after adding a file, run
#             `git add` or any jj command first.
#   -F FLAKE  build FLAKE#desk instead, e.g. github:iko-soy/deskjam or
#             "git+file://$PWD?rev=<commit>"
#   -d DIR    commit the desk in DIR as it is, e.g. `mortar build`'s dist
#   -v/-q/-m  passed to sync-desk.sh (verbatim log / quiet period / max wait)
#
# Exit status as sync-desk.sh: 0 ok; 1 build error or crash in the log
# (clay rejected the commit and the previous agent keeps running); 2
# harness problem, including a failed nix build. A rebuilt agent ends with
#   sync: %deskjam rev N -> N+1; reloaded: %deskjam; ok
# (from "gall: reloading %deskjam" in the log). If only files that aren't
# the agent's changed, or it compiled to the same code, there's no
# "reloaded".
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/env.sh"

FLAKE=$REPO SRC="" PASS=()
while getopts "F:d:vq:m:h" o; do
  case $o in
    F) FLAKE=$OPTARG ;;
    d) SRC=$OPTARG ;;
    v) PASS+=(-v) ;;
    q) PASS+=(-q "$OPTARG") ;;
    m) PASS+=(-m "$OPTARG") ;;
    *) usage_of "$0"; exit 64 ;;
  esac
done
if [[ -z $SRC ]]; then
  SRC=$(deskjam_build "$FLAKE") || { echo "sync-deskjam: nix build of $FLAKE's desk failed" >&2; exit 2; }
  echo "sync-deskjam: built $FLAKE's desk: $SRC"
fi
[[ -f $SRC/sys.kelvin ]] || { echo "sync-deskjam: $SRC isn't a desk (no sys.kelvin)" >&2; exit 2; }
if ! { rm -rf "$DIST" && mkdir -p "$DIST" && cp -R --no-preserve=mode "$SRC/." "$DIST/"; }; then
  echo "sync-deskjam: can't copy $SRC to $DIST" >&2; exit 2
fi
exec "$H/sync-desk.sh" "${PASS[@]}" deskjam "$DIST"
