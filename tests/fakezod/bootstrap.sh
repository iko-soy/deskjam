#!/usr/bin/env bash
# bootstrap.sh - boot a new fakezod from the pill, install %deskjam on it,
# and save the fresh pier as the snapshot that reset.sh restores. Leaves
# the ship running.
#
#   bootstrap.sh [-f] [-n] [-F FLAKE]
#
#   -f        replace an existing pier (stopping its ship first)
#   -n        don't save the snapshot (saves time and 600 MB of disk)
#   -F FLAKE  install FLAKE#deskjam instead of the repo's working copy,
#             e.g. github:iko-soy/deskjam or "git+file://$PWD?rev=<commit>"
#
# Steps: get urbit from nixpkgs and download the pill (once each); boot a
# new fakezod (about 3 minutes); |new-desk, sync and |install %harness,
# whose %logtap agent copies dill's output into the log; |new-desk %deskjam,
# sync the flake's build (sync-deskjam.sh) and |install it; check that the
# agent runs and that GET /apps/deskjam is 200 after logging in; make the
# %hello test desks (make-hello.sh); snapshot.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/env.sh"

FORCE=0 SNAP=1 FLAKE=$REPO
while getopts "fnF:" o; do
  case $o in
    f) FORCE=1 ;;
    n) SNAP=0 ;;
    F) FLAKE=$OPTARG ;;
    *) usage_of "$0"; exit 64 ;;
  esac
done
D="$H/dojo.sh"
step() { echo; echo "### $*"; }

if [[ -e $PIER ]]; then
  [[ $FORCE == 1 ]] || { echo "bootstrap: $PIER exists (use -f to replace it)" >&2; exit 1; }
  "$H/stop.sh"
  rm -rf "$PIER"
fi

step "build %deskjam ($FLAKE)"
DESKJAM=$(deskjam_build "$FLAKE")
echo "$DESKJAM"

step "boot a new fakezod"
"$H/start.sh" -c -w 1800
"$D" '+vats %base' | grep -E 'kelvin|hash'

wait_log() {  # mark regex what
  "$H/logsince.sh" -u "$2" -m 300 "$1" >/dev/null || { echo "bootstrap: timed out waiting for: $3" >&2; exit 1; }
}
new_desk() {  # an %ask generator: lens returns before hood acks; poll for the desk
  "$D" "|new-desk %$1" >/dev/null || true
  for _ in $(seq 60); do
    [[ $("$D" "(~(has in .^((set desk) %cd /=//=)) %$1)") == "%.y" ]] && return 0
    sleep 0.5
  done
  echo "bootstrap: |new-desk %$1 failed" >&2; exit 1
}

step "desk %harness with the %logtap agent"
# harness-desk/ plus the marks and libraries it needs, and deskjam's kelvin
rm -rf "$WORK/harness-desk"
mkdir -p "$WORK/harness-desk"
cp -R "$H/harness-desk/." "$WORK/harness-desk/"
for f in sys.kelvin mar/bill.hoon mar/hoon.hoon mar/kelvin.hoon mar/mime.hoon mar/noun.hoon \
         mar/txt.hoon mar/txt-diff.hoon lib/default-agent.hoon lib/skeleton.hoon; do
  install -D -m 644 "$DESKJAM/$f" "$WORK/harness-desk/$f"
done
new_desk harness
"$H/sync-desk.sh" harness "$WORK/harness-desk"
m=$(log_mark)
"$D" '|install our %harness'
wait_log "$m" 'gall: installing %logtap' '%logtap to start'
m=$(log_mark)
"$D" '|pass [%d %text "logtap check"]' >/dev/null
wait_log "$m" 'logtap: logtap check' 'logtap to echo dill output'
echo "logtap is running"

step "desk %deskjam"
new_desk deskjam
"$D" '|mount %deskjam'
"$H/sync-deskjam.sh" -d "$DESKJAM"
m=$(log_mark)
"$D" '|install our %deskjam'
wait_log "$m" 'gall: installing %deskjam|crud:|gall: failed' 'deskjam install'
sleep 1
"$H/logsince.sh" "$m"
"$D" '+vats %deskjam'
"$D" '+vats %deskjam' | grep -q 'app status: *running' || { echo "bootstrap: %deskjam is not running" >&2; exit 1; }

step "web login and GET /apps/deskjam"
"$H/login.sh"
code=$("$H/curl.sh" /apps/deskjam -o /dev/null -w '%{http_code}')
echo "GET /apps/deskjam -> $code"
[[ $code == 200 ]] || { echo "bootstrap: expected 200" >&2; exit 1; }

step "test desks"
"$H/make-hello.sh" -F "$FLAKE"

if [[ $SNAP == 1 ]]; then
  step "snapshot to $SNAPSHOT"
  "$H/snapshot.sh"
  "$H/login.sh"
fi
echo
echo "bootstrap: done. The ship is running$( ((SNAP)) && echo "; reset.sh restores this fresh state from $SNAPSHOT")."
