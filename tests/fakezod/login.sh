#!/usr/bin/env bash
# login.sh - log in to the fakezod's web interface: get +code through the
# dojo runner, POST it to /~/login and keep the session cookie in
# $COOKIES (used by curl.sh).  Prints the cookie name on success.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/env.sh"

code=$("$H/dojo.sh" '+code' | tr -d '[:space:]')
[[ $code =~ ^[a-z]{6}(-[a-z]{6}){3}$ ]] || { echo "login.sh: unexpected +code output: $code" >&2; exit 1; }
rm -f "$COOKIES"
status=$(curl -sS -o /dev/null -w '%{http_code}' -c "$COOKIES" \
  -X POST "$(base_url)/~/login" --data-urlencode "password=$code")
if [[ $status != 204 && $status != 200 && $status != 303 ]] || ! grep -q 'urbauth-' "$COOKIES"; then
  echo "login.sh: login failed (HTTP $status)" >&2; exit 1
fi
echo "login.sh: logged in to $(base_url) (HTTP $status), cookie $(awk '$6 ~ /^urbauth-/ {print $6}' "$COOKIES") in $COOKIES"
