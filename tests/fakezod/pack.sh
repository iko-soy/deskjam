#!/usr/bin/env bash
# pack.sh - pack a directory of desk files into a .deskjam file, as jammer
# does, with `urbit eval` (no ship needed).
#
#   pack.sh DIR DESK OUT.deskjam
#
# A .deskjam is the little-endian bytes of
#   (jam [%deskpack-0 desk=@tas (map path page:clay)])
# with every file a %mime page, [%mime /text/plain [size data]], which is
# what vere sends clay when you |commit a mount. A file's clay path is its
# path in DIR with the last dot a slash (app/foo.hoon is /app/foo/hoon).
# Hidden files are left out.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/env.sh"
[[ $# -eq 3 ]] || { usage_of "$0"; exit 64; }
dir=${1%/} desk=$2 out=$3
[[ -d $dir ]] || { echo "pack.sh: no directory $dir" >&2; exit 1; }
[[ $desk =~ ^[a-z][a-z0-9-]*$ ]] || { echo "pack.sh: bad desk name $desk" >&2; exit 1; }
need_urbit

# dots between groups of N digits, from the right: Hoon's 1.234 and 0xa.bcde
group() { rev | sed -E "s/([0-9a-f]{$1})/\\1./g; s/\\.\$//" | rev; }
# a file's bytes as a Hoon @ux literal, read as an atom (first byte lowest)
atom() {
  local h
  h=$(od -An -v -tx1 -w1 "$1" | tac | tr -d ' \n' | sed 's/^0*//')
  if [[ -z $h ]]; then echo 0x0; else echo "0x$(group 4 <<<"$h")"; fi
}

mapfile -t files < <(cd "$dir" && find . -type f ! -path '*/.*' | sed 's|^\./||' | LC_ALL=C sort)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
{
  echo ":-  %deskpack-0"
  echo ":-  %$desk"
  echo "%-  malt"
  echo "^-  (list [path page:clay])"
  echo ":~"
  for f in "${files[@]}"; do
    [[ $f =~ ^[a-z0-9._~/-]+\.[a-z0-9-]+$ ]] ||
      { echo "pack.sh: $dir/$f has no clay path" >&2; exit 1; }
    echo "  [/${f%.*}/${f##*.} %mime /text/plain $(stat -c %s "$dir/$f" | group 3) $(atom "$dir/$f")]"
  done
  echo "=="
} > "$tmp/pack.hoon"

# -j prints the result jammed, and -n in a newt frame: a version byte (0)
# and a 4-byte little-endian length, then the jam's bytes
"$URBIT" eval -jn < "$tmp/pack.hoon" > "$tmp/out" 2> "$tmp/err" || true
size=$(stat -c %s "$tmp/out")
read -r ver b0 b1 b2 b3 < <(od -An -v -tu1 -N5 "$tmp/out"; echo) || true
if [[ $size -lt 6 || ${ver:-} != 0 ]] ||
   (( b0 + (b1 << 8) + (b2 << 16) + (b3 << 24) != size - 5 )); then
  echo "pack.sh: urbit eval failed:" >&2
  tr -d '\r' < "$tmp/err" >&2
  tr -d '\r' < "$tmp/out" >&2
  exit 1
fi
tail -c +6 "$tmp/out" > "$out"
echo "pack.sh: $dir -> $out (${#files[@]} files, $((size - 5)) bytes)"
