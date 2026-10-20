#!/usr/bin/env bash
# build-file.sh - compile one file of a desk on the ship (the -build-file
# thread, i.e. clay's %a build) without committing anything, and print the
# compile error if there is one.
#
#   build-file.sh <desk> <path>        e.g.  build-file.sh deskjam /app/deskjam/hoon
#                                            build-file.sh deskjam app/deskjam.hoon
#
# Builds the file as currently committed in clay (sync first if needed; a
# rejected commit leaves the old version in clay).  Exit 0 if it built, 1 if
# not (the error and its source locations are printed), 2 harness problem.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/env.sh"
[[ $# -eq 2 ]] || { usage_of "$0"; exit 64; }
desk=${1#%} p=$2
# accept unix-style paths: app/foo.hoon -> /app/foo/hoon
if [[ $p != */hoon && $p == *.hoon ]]; then p="${p%.hoon}/hoon"; fi
[[ $p == /* ]] || p="/$p"

mark=$(log_mark)
out=$("$H/dojo.sh" -t 300 -- "-build-file /=$desk=$p")
rc=$?
sleep 0.5
if [[ $rc == 0 && $out != "thread failed"* ]]; then
  echo "build-file: /=$desk=$p OK"
  exit 0
fi
echo "build-file: /=$desk=$p FAILED"
printf '%s\n' "$out"
# clay slogs the build error; drop lens/dojo session noise
"$H/logsince.sh" -q 1 "$mark" | grep -vE '^! |^\[%dojo-lame|^%lens-cancel|/app/dojo/hoon|/sys/vane/gall/hoon:<\[1\.961'
exit 1
