#!/usr/bin/env bash
# stop.sh - stop the fakezod cleanly: SIGTERM to the king process (vere
# saves a snapshot and exits), then wait for the king and work processes
# to exit.
#
#   stop.sh [-w SECS]    (wait at most SECS, default 120; exit 1 if still up)
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/env.sh"

WAIT=120
while getopts "w:" o; do case $o in w) WAIT=$OPTARG ;; *) usage_of "$0"; exit 64 ;; esac; done

work=$(ship_pid || true)
king=$(king_pid || true)
if [[ -z $work && -z $king ]]; then echo "stop.sh: not running"; exit 0; fi
for p in $king $work; do
  # only ever signal our own urbit processes
  tr '\0' ' ' < "/proc/$p/cmdline" | grep -qF -- "$URBIT" ||
    { echo "stop.sh: pid $p is not our urbit ($(tr '\0' ' ' < "/proc/$p/cmdline"))" >&2; exit 1; }
done
echo "=== harness stop.sh $(date -Is) ===" >> "$LOG"
kill -TERM "${king:-$work}"
deadline=$(( $(date +%s) + WAIT ))
alive() { local p; for p in $king $work; do kill -0 "$p" 2>/dev/null && return 0; done; return 1; }
while alive; do
  if (( $(date +%s) > deadline )); then
    echo "stop.sh: still running after ${WAIT}s (king $king, work $work)" >&2; exit 1
  fi
  sleep 0.5
done
rm -f "$WORK/zod.pid"
echo "stop.sh: stopped (king $king, work $work)"
