#!/usr/bin/env bash
# make-hello.sh - (re)generate the %hello test desks and pack them into
# .deskjam files (pack.sh):
#
#   $APPS/hello-v1/      -> $APPS/hello-v1.deskjam
#   $APPS/hello-v2/      -> $APPS/hello-v2.deskjam
#   $APPS/hello-broken/  -> $APPS/hello-broken.deskjam
#
#   make-hello.sh [-F FLAKE]    take the marks and libraries from FLAKE's
#                               %deskjam build (default: the repo's)
#
# v1: agent %hello, state-0 [%0 count=@ud]; slogs "hello v1 init" in on-init
#     and "hello v1 load (...)" in on-load; imports /lib/hello-old.hoon; ships
#     /fil/notes.txt; docket version 0.0.1.
# v2: drops /lib/hello-old.hoon and /fil/notes.txt, adds /lib/hello-new.hoon
#     (imported instead); state-1 [%1 count=@ud note=@t] migrated from state-0
#     in on-load, which slogs "hello v2 load: migrated state-0 -> state-1";
#     fresh installs slog "hello v2 init"; docket version 0.0.2.
# broken: v2 whose /lib/hello-new.hoon has a type error (nest-fail), so any
#     build of the agent fails.
# All versions bind /apps/hello and answer GET with a one-line text/plain
# status such as "hello v1 state-0 count=1 greeting=hello from hello-old".
#
# The marks, libraries and /sys/kelvin are deskjam's, from `nix build
# .#deskjam`: base-dev's mar noun/hoon/txt/txt-diff/kelvin/bill/mime and lib
# default-agent/skeleton/dbug, and landscape's mar/docket-0, lib/docket and
# sur/docket, at the revisions flake.nix pins.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/env.sh"
FLAKE=$REPO
while getopts "F:" o; do
  case $o in
    F) FLAKE=$OPTARG ;;
    *) usage_of "$0"; exit 64 ;;
  esac
done
DESKJAM=$(deskjam_build "$FLAKE")

common() {  # dir: marks, libs, sys.kelvin, desk.bill
  local d=$1 f
  mkdir -p "$d"/{app,lib,mar,sur}
  for f in mar/noun.hoon mar/hoon.hoon mar/txt.hoon mar/txt-diff.hoon mar/kelvin.hoon \
           mar/bill.hoon mar/mime.hoon lib/default-agent.hoon lib/skeleton.hoon lib/dbug.hoon \
           mar/docket-0.hoon lib/docket.hoon sur/docket.hoon sys.kelvin; do
    install -m 644 "$DESKJAM/$f" "$d/$f"
  done
  printf ':~  %%hello\n==\n' > "$d/desk.bill"
}

docket() {  # dir version
  cat > "$1/desk.docket-0" <<EOF
:~  title+'Hello'
    info+'Test app for the deskjam harness.'
    color+0x81.88c9
    version+[$2]
    website+'https://example.com'
    license+'MIT'
    base+'hello'
    site+/apps/hello
==
EOF
}

# the HTTP + boilerplate arms shared by both agent versions ($1 = version
# label, $2 = state label, $3 = greeting expression)
http_arms() {
  cat <<EOF
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  ?.  ?=(%handle-http-request mark)
    (on-poke:def mark vase)
  =+  !<([eyre-id=@ta =inbound-request:eyre] vase)
  =/  body=@t
    %-  crip
    "hello $1 $2 count={(a-co:co count)} greeting={(trip $3)}\0a"
  =/  pax=path  /http-response/[eyre-id]
  =/  hed=response-header:http  [200 ['content-type' 'text/plain']~]
  :_  this
  :~  [%give %fact ~[pax] %http-response-header !>(hed)]
      [%give %fact ~[pax] %http-response-data !>(\`(unit octs)\`\`(as-octs:mimes:html body))]
      [%give %kick ~[pax] ~]
  ==
::
++  on-watch
  |=  =path
  ^-  (quip card _this)
  ?+  path  (on-watch:def path)
    [%http-response *]  \`this
  ==
::
++  on-arvo
  |=  [=wire =sign-arvo]
  ^-  (quip card _this)
  ?+  wire  (on-arvo:def wire sign-arvo)
    [%eyre %connect ~]  \`this
  ==
::
++  on-leave  on-leave:def
++  on-peek   on-peek:def
++  on-agent  on-agent:def
++  on-fail   on-fail:def
--
EOF
}

write_v1() {
  local d=$1
  rm -rf "$d"; common "$d"; docket "$d" '0 0 1'
  mkdir -p "$d/fil"
  printf 'notes for hello v1\nthis file is removed in v2\n' > "$d/fil/notes.txt"
  cat > "$d/lib/hello-old.hoon" <<'EOF'
::  hello-old: library used by hello v1 only (deleted in v2)
::
|%
++  greeting  'hello from hello-old'
--
EOF
  {
    cat <<'EOF'
::  hello v1: test agent for the deskjam harness
::
/+  default-agent, dbug, greet=hello-old
|%
+$  versioned-state  $%(state-0)
+$  state-0  [%0 count=@ud]
+$  card  card:agent:gall
--
%-  agent:dbug
=|  state-0
=*  state  -
^-  agent:gall
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this %|) bowl)
::
++  on-init
  ^-  (quip card _this)
  %-  (slog leaf+"hello v1 init" ~)
  :_  this(count 1)
  [%pass /eyre/connect %arvo %e %connect [~ /apps/hello] dap.bowl]~
::
++  on-save  !>(state)
::
++  on-load
  |=  ole=vase
  ^-  (quip card _this)
  =/  old  !<(versioned-state ole)
  %-  (slog leaf+"hello v1 load (state-0, count={(a-co:co count.old)}, {(trip greeting:greet)})" ~)
  `this(state old(count +(count.old)))
::
EOF
    http_arms v1 state-0 'greeting:greet'
  } > "$d/app/hello.hoon"
}

write_v2() {
  local d=$1
  rm -rf "$d"; common "$d"; docket "$d" '0 0 2'
  cat > "$d/lib/hello-new.hoon" <<'EOF'
::  hello-new: library used by hello v2 (replaces hello-old)
::
|%
++  greeting  'hello from hello-new'
--
EOF
  {
    cat <<'EOF'
::  hello v2: test agent for the deskjam harness
::
/+  default-agent, dbug, greet=hello-new
|%
+$  versioned-state  $%(state-0 state-1)
+$  state-0  [%0 count=@ud]
+$  state-1  [%1 count=@ud note=@t]
+$  card  card:agent:gall
--
%-  agent:dbug
=|  state-1
=*  state  -
^-  agent:gall
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this %|) bowl)
::
++  on-init
  ^-  (quip card _this)
  %-  (slog leaf+"hello v2 init" ~)
  :_  this(count 1, note 'fresh v2 install')
  [%pass /eyre/connect %arvo %e %connect [~ /apps/hello] dap.bowl]~
::
++  on-save  !>(state)
::
++  on-load
  |=  ole=vase
  ^-  (quip card _this)
  =/  old  !<(versioned-state ole)
  ?-    -.old
      %1
    %-  (slog leaf+"hello v2 load (state-1, count={(a-co:co count.old)}, {(trip greeting:greet)})" ~)
    `this(state old(count +(count.old)))
  ::
      %0
    %-  (slog leaf+"hello v2 load: migrated state-0 -> state-1 (count={(a-co:co count.old)}, {(trip greeting:greet)})" ~)
    `this(state [%1 +(count.old) 'migrated from state-0'])
  ==
::
EOF
    http_arms v2 'state-1 note={(trip note)}' 'greeting:greet'
  } > "$d/app/hello.hoon"
}

mkdir -p "$APPS"
write_v1 "$APPS/hello-v1"
write_v2 "$APPS/hello-v2"
write_v2 "$APPS/hello-broken"
cat > "$APPS/hello-broken/lib/hello-new.hoon" <<'EOF'
::  hello-new (BROKEN): type error on purpose -- a cell where @t is required
::
|%
++  greeting  ^-  @t  [%not-a-cord 42]
--
EOF

for v in v1 v2 broken; do
  "$H/pack.sh" "$APPS/hello-$v" hello "$APPS/hello-$v.deskjam"
done
