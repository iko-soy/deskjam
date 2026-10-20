#!/usr/bin/env bash
# logsince.sh - print ship log lines written after a mark from logmark.sh.
#
#   logsince.sh [-q SECS] [-m SECS] [-u REGEX] MARK
#
#   -q SECS   first wait until the log has been quiet (not grown) for SECS
#             seconds (default 0 = don't wait)
#   -u REGEX  first wait until a line matching REGEX (grep -E) appears
#   -m SECS   upper bound for either wait (default 120); exit 3 if -u timed out
#
# Carriage returns are stripped.  Output goes to stdout.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/env.sh"

QUIET=0 MAXWAIT=120 UNTIL=""
while getopts "q:m:u:h" o; do
  case $o in
    q) QUIET=$OPTARG ;;
    m) MAXWAIT=$OPTARG ;;
    u) UNTIL=$OPTARG ;;
    *) usage_of "$0"; exit 64 ;;
  esac
done
shift $((OPTIND - 1))
[[ $# -eq 1 && $1 =~ ^[0-9]+$ ]] || { usage_of "$0"; exit 64; }
MARK=$1

since() { tail -c +"$((MARK + 1))" "$LOG" | tr -d '\r'; }

rc=0
deadline=$(( $(date +%s) + MAXWAIT ))
if [[ -n $UNTIL ]]; then
  until since | grep -qE -- "$UNTIL"; do
    if (( $(date +%s) >= deadline )); then rc=3; break; fi
    sleep 0.25
  done
fi
if [[ $QUIET != 0 ]]; then
  last=$(log_mark); still=$(date +%s)
  while (( $(date +%s) < deadline )); do
    sleep 0.25
    cur=$(log_mark)
    if [[ $cur != "$last" ]]; then last=$cur; still=$(date +%s)
    elif (( $(date +%s) - still >= QUIET )); then break; fi
  done
fi
since
exit $rc
