#!/usr/bin/env bash
# dojo.sh - run one dojo command on the fakezod through the %lens agent
# (HTTP POST to the loopback port, which eyre treats as authenticated)
# and print its result.
#
#   dojo.sh [-l] [-q SECS] [-m SECS] [-t SECS] [-r] '<command>'
#
#   '+vats'                         generator / hoon / scry -> printed result
#   '.^((list path) %ct /=deskjam=)'
#   '|commit %deskjam'              hood command: run as +hood/commit with the
#                                   result poked into %hood (prints ">=" on ack)
#   ':app <source>'                 poke <source> (e.g. '&mark noun') into :app
#   '-build-file /=deskjam=/app/deskjam/hoon'   run a thread (spider)
#
#   -l        also print the ship's log lines produced by the command (hood
#             effects, clay/gall output, crashes).  Waits until the log has
#             been quiet for -q SECS (default 3) or -m SECS total (default 120)
#   -t SECS   give up waiting for the lens response after SECS (default 300);
#             the stuck lens job is cancelled so later calls keep working
#   -r        print the raw JSON response instead of decoding it
#
# Exit status: 0 ok; 1 dojo reported an error (hoon/generator/poke/thread
# failure, syntax error); 2 no response / lens or HTTP failure; 64 usage.
#
# NB: a command that pokes an agent that isn't running never gets acked
# (gall queues the poke), so it will hit the -t timeout.  Never print huge
# nouns as `*` (e.g. a vase): dojo's printer can spin for minutes; if the
# ship is busy like that, interrupt.sh aborts the event.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/env.sh"

usage() { usage_of "$0"; exit 64; }
TIMEOUT=300 SHOWLOG=0 QUIET=3 MAXWAIT=120 RAW=0
# hand-rolled option parsing so that thread commands ('-build-file ...')
# are taken as the command, not as options
while [[ $# -gt 0 ]]; do
  case $1 in
    -l) SHOWLOG=1; shift ;;
    -r) RAW=1; shift ;;
    -t|-q|-m) [[ $# -ge 2 ]] || usage
              case $1 in -t) TIMEOUT=$2 ;; -q) QUIET=$2 ;; -m) MAXWAIT=$2 ;; esac
              shift 2 ;;
    --) shift; break ;;
    -h|--help) usage ;;
    *) break ;;
  esac
done
[[ $# -eq 1 ]] || usage
cmd=$1

LPORT=$(loopback_port)
[[ -n $LPORT ]] || { echo "dojo.sh: no loopback port in $PIER/.http.ports (ship not running?)" >&2; exit 2; }
URL="http://127.0.0.1:$LPORT/"

# translate the command into a lens source + sink
trim() { local s=$1; s="${s#"${s%%[![:space:]]*}"}"; echo "${s%"${s##*[![:space:]]}"}"; }
cmd=$(trim "$cmd")
if [[ $cmd == \|* ]]; then          # |foo args  ->  +hood/foo args  >  :hood
  src="+hood/${cmd#|}"; sink='{"app":"hood"}'
elif [[ $cmd =~ ^:([a-z][a-z0-9-]*)[[:space:]]+(.+)$ ]]; then
  src=${BASH_REMATCH[2]}; sink=$(jq -cn --arg a "${BASH_REMATCH[1]}" '{app:$a}')
else
  src=$cmd; sink='{"stdout":null}'
fi
body=$(jq -cn --arg s "$src" --argjson k "$sink" '{source:{dojo:$s},sink:$k}')

cancel() {
  curl -sS -m 10 -o /dev/null -X POST "$URL" -H 'content-type: application/json' \
    -d '{"source":{"cancel":null},"sink":{"stdout":null}}' 2>/dev/null
}

# lens can only run one job at a time: serialize callers
exec 9>"$WORK/.lens.lock"
flock -w "$TIMEOUT" 9 || { echo "dojo.sh: timed out waiting for the lens lock" >&2; exit 2; }

mkdir -p "$WORK/tmp"; tmp=$(mktemp -d "$WORK/tmp/dojo.XXXXXX")
trap 'rm -rf "$tmp"; [[ -n ${cpid:-} ]] && kill "$cpid" 2>/dev/null' EXIT

run_once() {   # sets: code, rc
  mark=$(log_mark)
  curl -sS -m "$TIMEOUT" -o "$tmp/out" -w '%{http_code}' -X POST "$URL" \
    -H 'content-type: application/json' --data-binary "$body" >"$tmp/code" 2>"$tmp/err" &
  cpid=$!
  # a dojo syntax error makes the lens job hang forever; spot it in the log
  syntax=0
  while kill -0 "$cpid" 2>/dev/null; do
    if tail -c +"$((mark + 1))" "$LOG" 2>/dev/null | grep -q 'poke failed from %lens on wire /sole'; then
      syntax=1; kill "$cpid" 2>/dev/null; break
    fi
    sleep 0.1
  done
  wait "$cpid" 2>/dev/null; rc=$?; cpid=
  code=$(cat "$tmp/code" 2>/dev/null)
}

run_once
# a previous caller left a lens job behind: cancel it and retry once
if [[ $syntax == 0 && $code == 500 ]] && grep -q '/app/lens/hoon' "$tmp/out" 2>/dev/null; then
  cancel; run_once
fi

status=0
if [[ $syntax == 1 ]]; then
  cancel
  echo "dojo.sh: dojo rejected the command (see log below)" >&2
  sleep 0.3
  tail -c +"$((mark + 1))" "$LOG" | tr -d '\r' | sed -n '/poke failed from %lens/,$p' | head -40 >&2
  exit 1
elif [[ $code != 200 ]]; then
  cancel
  if [[ $rc == 28 ]]; then
    echo "dojo.sh: no response within ${TIMEOUT}s (lens job cancelled)." >&2
    w=$(ship_pid || true)
    if [[ -n $w ]]; then
      cpu=$(top -b -n 1 -p "$w" 2>/dev/null | awk -v p="$w" '$1==p {print int($9)}')
      if [[ ${cpu:-0} -ge 50 ]]; then
        echo "dojo.sh: the ship is still computing (work pid $w at ${cpu}% CPU); $H/interrupt.sh aborts that event" >&2
      fi
    fi
    echo "dojo.sh: log since the command:" >&2
  else
    echo "dojo.sh: HTTP ${code:-none} (curl rc=$rc) $(cat "$tmp/err")" >&2
    head -c 2000 "$tmp/out" >&2; echo >&2
  fi
  tail -c +"$((mark + 1))" "$LOG" | tr -d '\r' | tail -40 >&2
  exit 2
fi

if [[ $RAW == 1 ]]; then
  cat "$tmp/out"; echo
else
  jq -r 'if type=="string" then . elif type=="array" then .[] else tojson end' "$tmp/out" 2>/dev/null \
    | sed -e '${/^$/d;}' || cat "$tmp/out"
fi
if jq -r 'if type=="string" then . elif type=="array" then .[] else "" end' "$tmp/out" 2>/dev/null \
   | grep -qE '^dojo: .*fail|^>!|^thread failed'; then
  status=1
fi

if [[ $SHOWLOG == 1 ]]; then
  # drop the dojo/lens session noise that %ask generators (|new-desk, |nuke)
  # and threads leave behind: lens closes the dojo session on the first
  # output, so dojo's late poke-ack/kick handler crashes harmlessly
  "$H/logsince.sh" -q "$QUIET" -m "$MAXWAIT" "$mark" \
    | grep -vE '^! /sys/vane/gall/hoon:<\[1\.961 |^! /app/dojo/hoon:<\[|^! take %(poke-ack|kick) failed$|^\[%dojo-lame %(poke-ack|kick)\]$|^%lens-cancel$' \
    | sed 's/^/log| /'
fi
exit $status
