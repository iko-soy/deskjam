#!/usr/bin/env bash
# snapshot.sh - stop the ship cleanly, copy the pier to $SNAPSHOT (what
# reset.sh restores) and start the ship again.
#
#   snapshot.sh [-n] [DIR]    -n: leave the ship stopped; DIR: copy there
#                             instead of $SNAPSHOT
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/env.sh"
RESTART=1
while getopts "n" o; do case $o in n) RESTART=0 ;; *) usage_of "$0"; exit 64 ;; esac; done
shift $((OPTIND - 1))
DEST=${1:-$SNAPSHOT}
"$H/stop.sh"
rm -rf "$DEST.tmp"
cp -a --sparse=always "$PIER" "$DEST.tmp"
rm -f "$DEST.tmp/.vere.lock" "$DEST.tmp/.http.ports" "$DEST.tmp/.urb/conn.sock"
rm -rf "$DEST"; mv "$DEST.tmp" "$DEST"
echo "snapshot.sh: pier copied to $DEST ($(du -sh "$DEST" | cut -f1))"
if [[ $RESTART == 1 ]]; then "$H/start.sh"; fi
