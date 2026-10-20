::  logtap: re-emit dill's system output as slogs.
::
::    Test-harness helper.  vere run with -t/-d renders terminal blits with
::    a simplified printer that drops %mor blits, and drum wraps almost all
::    system output in %mor -- so %crud traces (e.g. a failed |commit) and
::    gall's %talk messages (e.g. agent build errors) never reach the log.
::    Slogs are printed by vere directly, so we subscribe to dill's %logs
::    and slog everything we hear, prefixed with "logtap: " on the
::    first line.
::
/+  default-agent
|%
+$  card  card:agent:gall
++  listen  `card`[%pass /logs %arvo %d %logs `~]
--
^-  agent:gall
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this %|) bowl)
++  on-init   [~[listen] this]
++  on-save   !>(~)
++  on-load   |=(vase [~[listen] this])
++  on-poke   on-poke:def
++  on-watch  on-watch:def
++  on-leave  on-leave:def
++  on-peek   on-peek:def
++  on-agent  on-agent:def
++  on-fail   on-fail:def
++  on-arvo
  |=  [=wire =sign-arvo]
  ^-  (quip card _this)
  ?.  ?=([%dill %logs *] sign-arvo)
    (on-arvo:def wire sign-arvo)
  =/  =told:dill  told.sign-arvo
  =/  out=tang
    ?-  -.told
      %crud  [leaf+"logtap: crud: %{(trip p.told)} event failed" (flop q.told)]
      %talk  ?~  p.told  ~
             ?:  ?=(%leaf -.i.p.told)
               [leaf+"logtap: {p.i.p.told}" t.p.told]
             [leaf+"logtap:" p.told]
      %text  [leaf+"logtap: {p.told}"]~
    ==
  %-  (slog out)
  [~ this]
--
