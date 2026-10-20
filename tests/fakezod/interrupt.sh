#!/usr/bin/env bash
# interrupt.sh - interrupt the event the ship is computing right now, like ^C
# in an interactive terminal: SIGINT to the work (mars/serf) process.  The
# event fails with %intr ("recover: dig: intr" in the log), is dropped, and
# the ship carries on.  Use it when dojo.sh times out and the work process
# sits at ~100% CPU (e.g. dojo pretty-printing a huge noun such as a vase
# printed as `*`, or an infinite loop in agent code).
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/env.sh"
w=$(ship_pid) || { echo "interrupt.sh: ship not running" >&2; exit 1; }
tr '\0' ' ' < "/proc/$w/cmdline" | grep -qF -- "$URBIT" || { echo "interrupt.sh: pid $w is not our urbit" >&2; exit 1; }
m=$(log_mark)
kill -INT "$w"
sleep 2
"$H/logsince.sh" "$m" | head -5
echo "interrupt.sh: sent SIGINT to work pid $w"
