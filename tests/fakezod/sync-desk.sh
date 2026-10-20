#!/usr/bin/env bash
# sync-desk.sh - make a mounted desk identical to a source directory, run
# |commit, wait for clay/gall to finish, and print what the ship logged.
#
#   sync-desk.sh [-v] [-q SECS] [-m SECS] <desk> <srcdir>
#
#   -q SECS   after the commit, wait until the log has been quiet this long
#             (default 2)
#   -m SECS   upper bound for that wait (default 300)
#   -v        print the log verbatim (by default runs of kernel stack-trace
#             lines "/sys/...hoon:<[..]>" are collapsed into one line)
#
# The desk must already exist (|new-desk); it is mounted if needed.  Files in
# the mount that are not in <srcdir> are deleted (rsync --delete), so the
# commit also deletes them from clay.  The copies are writable, even from a
# read-only <srcdir> such as a Nix build, so that clay can update the mount.
#
# Exit status:
#   0  committed (or nothing to commit) and no error in the log
#   1  the log shows a build error / crash / trace (commit probably rejected)
#   2  harness problem (ship down, desk missing, ...)
# The last line is a summary such as
#   sync: %deskjam rev 4 -> 5; reloaded: %deskjam
#   sync: %deskjam rev 5 -> 5 (unchanged); FAILED: log shows errors
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/env.sh"

QUIET=2 MAXWAIT=300 VERBOSE=0
while getopts "q:m:vh" o; do
  case $o in
    v) VERBOSE=1 ;;
    q) QUIET=$OPTARG ;;
    m) MAXWAIT=$OPTARG ;;
    *) usage_of "$0"; exit 64 ;;
  esac
done
shift $((OPTIND - 1))
[[ $# -eq 2 ]] || { usage_of "$0"; exit 64; }
desk=${1#%} src=${2%/}
[[ -d $src ]] || { echo "sync: no such directory $src" >&2; exit 2; }
ship_pid >/dev/null || { echo "sync: ship is not running" >&2; exit 2; }

D="$H/dojo.sh"
has=$("$D" "(~(has in .^((set desk) %cd /=//=)) %$desk)") || exit 2
[[ $has == "%.y" ]] || { echo "sync: desk %$desk does not exist (|new-desk %$desk first)" >&2; exit 2; }

mnt="$PIER/$desk"
if [[ ! -d $mnt ]]; then
  "$D" "|mount %$desk" >/dev/null || exit 2
  for _ in $(seq 50); do [[ -d $mnt ]] && break; sleep 0.2; done
  [[ -d $mnt ]] || { echo "sync: mounting %$desk did not create $mnt" >&2; exit 2; }
fi

rev() { "$D" ".^(cass:clay %cw /=$desk=)" | sed -nE 's/^\[ud=([0-9]+) .*/\1/p'; }
before=$(rev)

echo "sync: $src -> $mnt"
rsync -a --chmod=u+w --delete --checksum --itemize-changes "$src/" "$mnt/" \
  | grep -vE '^\.[df]' | sed -E 's/^\*deleting +/  deleted   /; s/^>f\+{9} /  added     /; s/^>f[^ ]* /  changed   /; s/^cd\+{9} /  new dir   /'

mark=$(log_mark)
out=$("$D" "|commit %$desk") || { echo "sync: |commit failed: $out" >&2; exit 2; }
# barrier: vere plans the %into while handling the |commit effects, so a
# later lens request is only answered after the commit event has run
"$D" now >/dev/null || exit 2
sleep 0.3
log=$("$H/logsince.sh" -q "$QUIET" -m "$MAXWAIT" "$mark")
after=$(rev)

collapse() {   # fold runs of /sys/... trace lines
  awk '/^\/sys\/[^ ]*hoon:<\[/ { if (!n) first=$0; n++; next }
       { if (n) { print (n == 1 ? first : "  [" n " kernel trace lines, " first " ...]"); n=0 } print }
       END { if (n) print (n == 1 ? first : "  [" n " kernel trace lines, " first " ...]") }'
}
if [[ -n $log ]]; then
  if [[ $VERBOSE == 1 ]]; then printf '%s\n' "$log"; else printf '%s\n' "$log" | collapse; fi | sed 's/^/log| /'
fi

# build errors, crashes and stack-trace lines (desk code "/app/x/hoon::[12 3]..",
# kernel "/sys/vane/clay/hoon:<[4.669 3]..")
ERR_RE='crud: |event failed|gall: failed|nest-fail|mint-|mull-|find-fork|-find\.|syntax error|bail: |ford: |%error|crash|^>>>|^/[^ ]+/hoon::?<?\['
reloaded=$(printf '%s\n' "$log" | sed -nE 's/^gall: (installing|reloading|reviving|unnuking) (%[a-z0-9-]+).*/\2/p' | sort -u | tr '\n' ' ')
summary="sync: %$desk rev $before -> $after"
[[ $before == "$after" ]] && summary+=" (unchanged)"
[[ -n $reloaded ]] && summary+="; reloaded: ${reloaded% }"
if printf '%s\n' "$log" | grep -qE -- "$ERR_RE"; then
  # innermost source position in the desk (lines like /app/x/hoon::[12 3].[12 9]>)
  where=$(printf '%s\n' "$log" | grep -m1 -E '^/[^ ]+/hoon::\[' || true)
  [[ -n $where ]] && echo "sync: first error location in desk code: $where"
  echo "$summary; FAILED: log shows errors"
  exit 1
fi
echo "$summary; ok"
