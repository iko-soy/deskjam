#!/usr/bin/env bash
# curl.sh - curl against the fakezod's web interface with the login cookie.
#
#   curl.sh PATH [curl options...]
#
# PATH is relative to the ship's base URL (http://127.0.0.1:$HTTP_PORT), e.g.
#   curl.sh /apps/deskjam -i
#   curl.sh /apps/deskjam -F file=@hello-v1.deskjam -i
#   curl.sh /apps/deskjam/staged -d mode=n -d desk=hello -L
# Adds -sS and the cookie jar ($COOKIES, run login.sh first).
# Redirects are not followed unless you pass -L.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/env.sh"
[[ $# -ge 1 && $1 == /* ]] || { usage_of "$0"; exit 64; }
path=$1; shift
[[ -s $COOKIES ]] || echo "curl.sh: warning: no cookie in $COOKIES, run login.sh" >&2
exec curl -sS -b "$COOKIES" -c "$COOKIES" "$@" "$(base_url)$path"
