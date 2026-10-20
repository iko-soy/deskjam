#!/usr/bin/env bash
# reset.sh - throw away the pier, restore the snapshot bootstrap.sh saved
# (a fresh fakezod with %harness and %deskjam installed, and no %hello),
# start the ship and log in again (login.sh).
#
#   reset.sh [-n] [DIR]    -n: leave the ship stopped; DIR: restore from DIR
#                          instead of $SNAPSHOT
#
# Takes about 5 to 10 seconds. Then run sync-deskjam.sh to put your
# working copy of deskjam on the ship. The log is kept, with a marker line.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/env.sh"
RESTART=1
while getopts "n" o; do case $o in n) RESTART=0 ;; *) usage_of "$0"; exit 64 ;; esac; done
shift $((OPTIND - 1))
SRC=${1:-$SNAPSHOT}
[[ -d $SRC/.urb ]] || { echo "reset.sh: no snapshot at $SRC (run bootstrap.sh)" >&2; exit 1; }
"$H/stop.sh"
echo "=== harness reset.sh from $SRC $(date -Is) ===" >> "$LOG"
rm -rf "$PIER"
cp -a --sparse=always "$SRC" "$PIER"
echo "reset.sh: restored $PIER from $SRC"
if [[ $RESTART == 1 ]]; then
  "$H/start.sh"
  "$H/login.sh"
fi
