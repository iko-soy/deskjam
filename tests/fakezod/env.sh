# env.sh - settings and helpers for the fakezod harness. The scripts source
# it. Every setting can be overridden from the environment.
# shellcheck shell=bash disable=SC2034

H="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # this directory
REPO="${REPO:-$(cd "$H/../.." && pwd)}"             # the deskjam repo
WORK="${WORK:-$H/.work}"                             # all the harness makes (gitignored)
mkdir -p "$WORK" && WORK="$(cd "$WORK" && pwd)"
URBIT="${URBIT:-$WORK/urbit/bin/urbit}"              # vere; need_urbit builds it
PIER="${PIER:-$WORK/zod}"                            # the fakezod's pier
LOG="${LOG:-$WORK/zod.log}"                          # all of vere's output goes here
PILL="${PILL:-$WORK/dl/urbit-v4.6.pill}"             # boot pill, downloaded once
PILL_URL="${PILL_URL:-https://bootstrap.urbit.org/urbit-v4.6.pill}"
PILL_SHA256="${PILL_SHA256:-f8b08c53dd6d0aa9c4f7654f0a7bcd11e94089222888a3c99c0a10eedcbb377b}"
HTTP_PORT="${HTTP_PORT:-8483}"                       # web interface, on 127.0.0.1 only
AMES_PORT="${AMES_PORT:-31483}"                      # fake ames, unused
DIST="${DIST:-$WORK/dist}"                           # writable copy of the %deskjam build
APPS="${APPS:-$WORK/apps}"                           # test desks (make-hello.sh)
COOKIES="${COOKIES:-$WORK/cookies.txt}"              # web login cookie (login.sh)
SNAPSHOT="${SNAPSHOT:-$WORK/zod-fresh}"              # fresh pier that reset.sh restores
URBIT_FLAGS=(-d --no-dock --http-port "$HTTP_PORT" -b 127.0.0.1 -p "$AMES_PORT")

# Ports the running ship bound, from <pier>/.http.ports, such as
#   "8483 insecure public" / "12321 insecure loopback"
# vere takes the next free port when one is in use.
loopback_port() { awk '$3=="loopback"{print $1; exit}' "$PIER/.http.ports" 2>/dev/null; }
public_port()   { awk '$3=="public"{print $1; exit}'   "$PIER/.http.ports" 2>/dev/null; }
base_url()      { echo "http://127.0.0.1:$(public_port || echo "$HTTP_PORT")"; }

# PID of the running "work" (mars/serf) process, from <pier>/.vere.lock
ship_pid() {
  local p
  p=$(tr -dc 0-9 2>/dev/null < "$PIER/.vere.lock") || return 1
  [[ -n $p ]] && kill -0 "$p" 2>/dev/null && echo "$p"
}
# PID of the king (urth) process: the parent of the work process, or else
# a process running our binary on our pier
king_pid() {
  local w k
  if w=$(ship_pid); then
    k=$(ps -o ppid= -p "$w" | tr -d ' ')
    [[ -n $k && $k != 1 ]] && { echo "$k"; return 0; }
  fi
  pgrep -f -- "^$URBIT .*$PIER\$" | head -1 | grep .
}

# Current size of the log in bytes (a mark for logsince.sh)
log_mark() { stat -c %s "$LOG" 2>/dev/null || echo 0; }

# Print a script's leading comment block (its usage) to stderr
usage_of() { awk 'NR == 1 { next } /^#/ { print; next } { exit }' "$1" >&2; }

# Make sure $URBIT exists. By default it's nixpkgs' urbit, from the
# nixpkgs that the repo's flake.lock pins, linked (as a GC root) at
# $WORK/urbit.
need_urbit() {
  [[ -x $URBIT ]] && return 0
  if [[ $URBIT == "$WORK/urbit/bin/urbit" ]]; then
    echo "getting urbit from the nixpkgs in $REPO/flake.lock" >&2
    nix build --inputs-from "$REPO" --out-link "$WORK/urbit" nixpkgs#urbit >&2 || return 1
  fi
  [[ -x $URBIT ]] || { echo "no urbit binary at $URBIT" >&2; return 1; }
}

# Make sure $PILL exists and has the pinned sha256, downloading it from
# $PILL_URL if it's missing
need_pill() {
  local sum
  if [[ ! -s $PILL ]]; then
    mkdir -p "$(dirname "$PILL")"
    echo "downloading $PILL_URL (about 220 MB)" >&2
    curl -fsSL --retry 3 -o "$PILL.part" "$PILL_URL" || { rm -f "$PILL.part"; return 1; }
    sum=$(sha256sum "$PILL.part" | cut -d ' ' -f 1)
    if [[ $sum != "$PILL_SHA256" ]]; then
      echo "$PILL_URL has sha256 $sum, not $PILL_SHA256" >&2
      rm -f "$PILL.part"
      return 1
    fi
    mv "$PILL.part" "$PILL"
    return 0
  fi
  sum=$(sha256sum "$PILL" | cut -d ' ' -f 1)
  if [[ $sum != "$PILL_SHA256" ]]; then
    echo "$PILL has sha256 $sum, not $PILL_SHA256. Delete it to download it again." >&2
    return 1
  fi
}

# The store path of the %deskjam desk that FLAKE (default: the repo's
# working copy) builds. Nix only sees files git knows about.
deskjam_build() { nix build --no-link --print-out-paths "${1:-$REPO}#deskjam"; }
