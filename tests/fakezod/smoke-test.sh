#!/usr/bin/env bash
# smoke-test.sh - drive deskjam's web interface with curl, as a browser
# would, and check what it does:
#
#   1. forms that pages on other sites send get 403, and stage nothing
#   2. upload hello-v1.deskjam, install it as the new desk %hello and tick
#      "start its agents after uploading": the status page says it's done,
#      %hello has exactly the upload's files, and its agent starts and
#      serves /apps/hello
#   3. upload hello-v2.deskjam and replace %hello with it: the files v2
#      dropped are deleted, and the running agent reloads and migrates
#      its state
#   4. deskjam's older form fields still work: install hello-v1 again as
#      %hello-copy, which starts suspended
#
#   smoke-test.sh
#
# Run it on a fresh ship (bootstrap.sh, or reset.sh after one). The test
# desks come from make-hello.sh, which runs if they're missing. The pages
# it gets are saved in $WORK/tmp/smoke/.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/env.sh"

C="$H/curl.sh" D="$H/dojo.sh"
OUT="$WORK/tmp/smoke"
rm -rf "$OUT"
mkdir -p "$OUT"
fail() { echo "smoke-test: FAIL: $*" >&2; exit 1; }
text() { tr '\n' ' ' < "$OUT/$1.html" | sed -e 's|<style>.*</style>||; s/<[^>]*>/ /g' | tr -s ' ' | head -c 3000; echo; }
# req NAME CODE LOCATION -- PATH [curl args]: send a request, save its body
# as NAME.html, check its status and, unless LOCATION is "", that it
# redirects there
req() {
  local name=$1 code=$2 loc=$3 got
  shift 4
  got=$("$C" "$@" -o "$OUT/$name.html" -w '%{http_code} %{redirect_url}') || fail "$name: curl failed"
  echo "$name: HTTP $got"
  if [[ ${got%% *} != "$code" ]]; then
    text "$name" >&2
    fail "$name: expected HTTP $code"
  fi
  [[ -z $loc || ${got#* } == "$(base_url)$loc"* ]] || fail "$name: expected a redirect to $loc"
}
# has NAME TEXT: the page saved as NAME has TEXT
has() { grep -qF -- "$2" "$OUT/$1.html" || { text "$1" >&2; fail "$1 doesn't have: $2"; }; }
# hidden NAME FIELD: the value of a hidden input on the page saved as NAME
hidden() { { grep -o "name=\"$2\" value=\"[^\"]*\"" "$OUT/$1.html" || true; } | head -1 | sed 's/.*value="//; s/"$//'; }
# commit NAME CONFIRM [curl args]: post the form on the confirm page saved
# as CONFIRM, with its hidden fields, as the browser would, and expect the
# status page
commit() {
  local name=$1 page=$2 desk field
  local -a fields=()
  shift 2
  desk=$(hidden "$page" desk)
  [[ -n $desk ]] || { text "$page" >&2; fail "$page has no form to confirm"; }
  while IFS= read -r field; do
    fields+=(--data-urlencode "$field")
  done < <(grep -o '<input type="hidden" name="[^"]*" value="[^"]*"' "$OUT/$page.html" |
             sed -E 's/.* name="([^"]*)" value="([^"]*)"$/\1=\2/')
  req "$name" 303 "/apps/deskjam/status?desk=$desk" -- /apps/deskjam/confirm "${SAME[@]}" \
    "${fields[@]}" "$@" -d commit=y
}
upload() {  # NAME FILE
  req "$1" 303 /apps/deskjam/staged -- /apps/deskjam "${SAME[@]}" \
    -F "file=@$2;type=application/octet-stream"
}
# same_files DESK DIR: the desk has exactly the files in DIR
same_files() {
  local got want
  "$D" now >/dev/null   # a barrier: the events before it have run
  got=$("$D" ".^((list path) %ct /=$1=)" | tr -d '~[]\n' | tr ' ' '\n' | { grep . || true; } | sort)
  want=$(cd "$2" && find . -type f ! -path '*/.*' | sed -E 's|^\./|/|; s|\.([^./]+)$|/\1|' | sort)
  if [[ $got != "$want" ]]; then
    diff <(echo "$want") <(echo "$got") >&2 || true
    fail "%$1's files aren't those in $2 (<: only in $2, >: only in %$1)"
  fi
  echo "%$1 has the $(wc -l <<<"$got") files in $2"
}
# logged MARK REGEX: wait until the log has a line matching REGEX since MARK
logged() {
  "$H/logsince.sh" -u "$2|crud:|gall: failed" -m 120 "$1" >/dev/null || true
  sleep 1
  "$H/logsince.sh" "$1" | sed 's/^/log| /'
  "$H/logsince.sh" "$1" | grep -qE -- "$2" || fail "the log doesn't say: $2"
}

[[ -s $APPS/hello-v1.deskjam && -s $APPS/hello-v2.deskjam ]] || "$H/make-hello.sh"
"$H/login.sh"
# what a browser sends with a form from the ship's own pages over http
SAME=(-H "Origin: $(base_url)")

echo "### 1. forms from other sites are refused"
req cross-site 403 "" -- /apps/deskjam -H 'Sec-Fetch-Site: cross-site' \
  -H 'Origin: https://evil.example' -F "file=@$APPS/hello-v1.deskjam;type=application/octet-stream"
req other-origin 403 "" -- /apps/deskjam -H 'Origin: https://evil.example' \
  -F "file=@$APPS/hello-v1.deskjam;type=application/octet-stream"
req nothing-staged 200 "" -- /apps/deskjam/staged
has nothing-staged 'Nothing is staged.'

echo "### 2. install hello-v1 as the new desk %hello, and start it"
upload upload-v1 "$APPS/hello-v1.deskjam"
req staged-v1 200 "" -- /apps/deskjam/staged
has staged-v1 '<h1>%hello</h1>'
has staged-v1 'name="mode" value="n"'
req dest-v1 303 /apps/deskjam/confirm -- /apps/deskjam/staged "${SAME[@]}" -d mode=n -d desk=hello
req confirm-v1 200 "" -- /apps/deskjam/confirm
has confirm-v1 'install %hello as the new desk %hello'
has confirm-v1 'name="revive"'
m=$(log_mark)
commit commit-v1 confirm-v1 -d revive=y
logged "$m" 'hello v1 init'
req status-v1 200 "" -- '/apps/deskjam/status?desk=hello'
has status-v1 'Done: %hello is now at revision'
has status-v1 '%hello (running)'
same_files hello "$APPS/hello-v1"
req app-v1 200 "" -- /apps/hello
has app-v1 'hello v1 state-0 count=1'

echo "### 3. replace %hello with hello-v2"
upload upload-v2 "$APPS/hello-v2.deskjam"
req dest-v2 303 /apps/deskjam/confirm -- /apps/deskjam/staged "${SAME[@]}" -d mode=r -d desk=hello
req confirm-v2 200 "" -- /apps/deskjam/confirm
has confirm-v2 'replace %hello with %hello'
has confirm-v2 'files to delete (2)'
m=$(log_mark)
commit commit-v2 confirm-v2
logged "$m" 'hello v2 load: migrated state-0 -> state-1'
req status-v2 200 "" -- '/apps/deskjam/status?desk=hello'
has status-v2 'Done: %hello is now at revision'
has status-v2 '%hello (running)'
same_files hello "$APPS/hello-v2"
req app-v2 200 "" -- /apps/hello
has app-v2 'hello v2 state-1 note=migrated from state-0 count=2'

echo "### 4. the older form fields: hello-v1 as the new desk %hello-copy"
upload upload-copy "$APPS/hello-v1.deskjam"
req dest-copy 303 /apps/deskjam/confirm -- /apps/deskjam/staged "${SAME[@]}" -d new-desk=hello-copy
req commit-copy 303 /apps/deskjam -- /apps/deskjam/confirm "${SAME[@]}" -d new-desk=
same_files hello-copy "$APPS/hello-v1"
"$D" '+vats %hello-copy' | tee "$OUT/vats-copy.txt"
grep -qE 'app status: +suspended' "$OUT/vats-copy.txt" || fail "%hello-copy isn't suspended"

echo "smoke-test: PASS"
