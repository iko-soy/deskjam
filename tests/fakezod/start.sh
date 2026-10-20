#!/usr/bin/env bash
# start.sh - start the fakezod ($PIER) in the background and wait until it
# has booted and %lens answers. All of vere's output goes to $LOG.
#
#   start.sh [-w SECS]     start the existing pier (wait at most SECS, 600)
#   start.sh -c [-w SECS]  boot a NEW fakezod from the pill (about 3
#                          minutes); refuses if $PIER exists
#
# vere runs as `urbit -d --no-dock --http-port $HTTP_PORT -b 127.0.0.1
# -p $AMES_PORT $PIER` (a new pier adds -F zod -c $PIER -B $PILL): -d is
# daemon mode, which forks once the ship has booted, never reads stdin and
# implies -t (no tty). It picks the loopback (lens) port itself, 12321 or
# the next free one; the scripts read it from $PIER/.http.ports.
#
# NB: with -t, vere drops %mor terminal blits, which is almost all that
# dill prints (dojo output, %talk, %crud traces). The %logtap agent on
# desk %harness (bootstrap.sh installs it) slogs that output, so it reaches
# the log. vere's output goes through `cat`, so that writes to fd 1 always
# see a pipe.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/env.sh"

WAIT=600 CREATE=0
while getopts "cw:" o; do
  case $o in
    c) CREATE=1 ;;
    w) WAIT=$OPTARG ;;
    *) usage_of "$0"; exit 64 ;;
  esac
done

if pid=$(ship_pid); then
  echo "start.sh: already running (work pid $pid, king pid $(king_pid))"; exit 0
fi
need_urbit
if [[ $CREATE == 1 ]]; then
  [[ ! -e $PIER ]] || { echo "start.sh: $PIER already exists" >&2; exit 1; }
  need_pill
  ARGS=(-F zod -c "$PIER" -B "$PILL" "${URBIT_FLAGS[@]}")
else
  [[ -d $PIER/.urb ]] || { echo "start.sh: no pier at $PIER (run bootstrap.sh)" >&2; exit 1; }
  rm -f "$PIER/.http.ports" "$PIER/.vere.lock"
  ARGS=("${URBIT_FLAGS[@]}" "$PIER")
fi

mkdir -p "$(dirname "$LOG")"
mark=$(log_mark)
echo "=== harness start.sh $( ((CREATE)) && echo '-c ')$(date -Is) ===" >> "$LOG"
# shellcheck disable=SC2016 # the inner bash expands these
HARNESS_LOG="$LOG" setsid bash -c 'exec "$0" "$@" < /dev/null 2>&1 | exec cat >> "$HARNESS_LOG"' \
  "$URBIT" "${ARGS[@]}" &
disown || true

deadline=$(( $(date +%s) + WAIT ))
while :; do
  if [[ -s $PIER/.http.ports ]] && lp=$(loopback_port) && [[ -n $lp ]] &&
     curl -sf -m 5 -X POST "http://127.0.0.1:$lp/" -H 'content-type: application/json' \
       -d '{"source":{"dojo":"our"},"sink":{"stdout":null}}' >/dev/null 2>&1; then
    break
  fi
  if (( $(date +%s) > deadline )); then
    echo "start.sh: ship not up after ${WAIT}s; log tail:" >&2
    tail -c +"$((mark + 1))" "$LOG" | tr -d '\r' | tail -30 >&2
    exit 1
  fi
  if (( $(date +%s) > $(stat -c %Y "$LOG") + 10 )) && ! pgrep -f -- "^$URBIT " >/dev/null; then
    echo "start.sh: urbit exited during boot; log tail:" >&2
    tail -c +"$((mark + 1))" "$LOG" | tr -d '\r' | tail -30 >&2
    exit 1
  fi
  sleep 1
done
king_pid > "$WORK/zod.pid"
echo "start.sh: up. king pid $(king_pid), work pid $(ship_pid), http $(public_port), loopback $(loopback_port), log $LOG"
