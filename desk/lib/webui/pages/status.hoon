/-  *deskjam
/+  sty=webui-styles, h=deskjam, par=webui-parts
|_  [=bowl:gall data dex=(unit desk) msg=(unit [o=? =@t])]
+*  hc  ~(. h [our now]:bowl)
++  page
  ^-  manx
  ;html(lang "en")
    ;head
      ;title: {?~(dex "Deskjam: status" "Deskjam: status of %{(trip u.dex)}")}
      ;meta(charset "utf-8");
      ;meta
        =name     "viewport"
        =content  "width=device-width, initial-scale=1";
      ;style: {global:sty}
    ==
    ;body
      ;a/"/apps/deskjam": return home
      ;*  (banner:par msg)
      ;+  ?~  dex  choose
          (report u.dex)
    ==
  ==
::
::  +choose: ask which desk to show
::
++  choose
  ^-  manx
  ;form(method "get", action "/apps/deskjam/status", class "justified-form")
    ;select(name "desk", required "required", aria-label "desk")
      ;*  %+  turn  (sort ~(tap in desks:hc) aor)
          |=  =desk
          ^-  manx
          ;option(value (trip desk)): {(trip desk)}
    ==
    ;button(type "submit"): status
  ==
::
::  +report: the state of a desk, and whether our last commit landed
::
++  report
  |=  =desk
  ^-  manx
  =/  nom=tape  "%{(trip desk)}"
  =/  dom=(unit dome:clay)  (~(get by domes:hc) desk)
  ?~  dom
    ;p: There is no desk called {nom}.
  =/  waits=(set weft)
    (silt (skim ~(tap in ~(key by wic.u.dom)) newer:hc))
  =/  waiting=tape  ?:(=(~ waits) "none" (wefts-tape:hc waits))
  ?:  =(0 let.u.dom)
    ;div
      ;h1: {nom}
      ;*  (outcome desk u.dom)
      ;p: {nom} has no commits yet. Updates waiting for a newer kernel: {waiting}.
    ==
  =/  doc  (biff (desk-page:hc desk /desk/docket-0) read-docket:hc)
  =/  kel  (biff (desk-page:hc desk /sys/kelvin) read-kelvins:hc)
  =/  syn  (~(get ja syncs:hc) desk)
  ;div
    ;h1: {nom}
    ;*  (outcome desk u.dom)
    ;table
      ;tr
        ;td: app
        ;td
          ; {?~(doc "-" "{(trip title.u.doc)} {(version-tape:hc version.u.doc)}")}
        ==
      ==
      ;tr
        ;td: revision
        ;td: {(a-co:co let.u.dom)}
      ==
      ;tr
        ;td: status
        ;td: {(zest-tape:hc liv.u.dom)}
      ==
      ;tr
        ;td: agents
        ;td: {(agents-tape desk)}
      ==
      ;tr
        ;td: kernel
        ;td: {?~(kel "unknown" (wefts-tape:hc u.kel))}
      ==
      ;*  ?~  ref=(glob-ref:hc doc)  ~
          :_  ~
          ;tr
            ;td: glob
            ;td: {(glob-tape:hc u.ref)}
          ==
      ;tr
        ;td: synced
        ;td
          ; {?~(syn "no" (zing (join "; " (turn syn sync-tape:hc))))}
        ==
      ==
      ;tr
        ;td: waiting
        ;td: {waiting}
      ==
    ==
    ;br;
    ;a(href "/apps/deskjam/download?desk={(trip desk)}"): download {nom}
  ==
::
::  +outcome: what became of the commit deskjam last sent here
::
++  outcome
  |=  [=desk dom=dome:clay]
  ^-  marl
  ?~  sent  ~
  ?.  =(desk desk.u.sent)  ~
  =/  nom=tape  "%{(trip desk)}"
  =/  syn  (~(get ja syncs:hc) desk)
  %+  weld
    ^-  marl
    :_  ~
    ?:  (gth let.dom rev.u.sent)
      ;p.ok: Done: {nom} is now at revision {(a-co:co let.dom)}.
    ?:  held.u.sent
      ::  clay only applies held commits to running desks at an upgrade
      ::
      ?:  ?=(%live liv.dom)
        ;p: Clay is holding the upload until your ship upgrades to a kernel it supports (see "waiting" below). Nothing has changed yet.
      ?:  =(0 let.dom)
        ;p: Clay created {nom} with no files and is holding the upload, but only applies held uploads to desks that are running when your ship upgrades. After the upgrade, upload it again and merge it into {nom}.
      ;p: Clay is holding the upload, but only applies held uploads to desks that are running when your ship upgrades. Upload it again after the upgrade.
    ;p: {nom} already had exactly these files, so Clay made no new revision.
  ^-  marl
  %+  weld
    ^-  marl
    ?.  &(start.u.sent !held.u.sent !?=(%live liv.dom))  ~
    :_  ~
    ;p.bad: Clay didn't start {nom}. Your ship's dojo shows why.
  ^-  marl
  %+  weld
    ^-  marl
    ::  as with |new-desk, a new desk starts suspended unless asked
    ::
    ?.  &(!start.u.sent !held.u.sent !?=(%live liv.dom) !=(%kids desk))
      ~
    :_  ~
    ;p: {nom} is suspended, so its agents don't run, and Landscape shows no tile for an app that has never run. To start it, run |revive {nom} in the dojo, which says why if it can't.
  ^-  marl
  ?~  syn  ~
  =/  stop=tape  ?^(via.i.syn "" ". Run |pause {nom} to stop that")
  :_  ~
  ;p.bad: {nom} is still overwritten from outside ({(sync-tape:hc i.syn)}), so its next update will undo this upload{stop}.
::
::  +agents-tape: the agents a desk's bill lists, and any others it has
::
++  agents-tape
  |=  =desk
  ^-  tape
  =/  bill=(list dude:gall)
    (fall (biff (desk-page:hc desk /desk/bill) read-dudes:hc) ~)
  =/  have=(map dude:gall ?)  (malt ~(tap in (agents:hc desk)))
  =/  listed=(list tape)
    %+  turn  bill
    |=  d=dude:gall
    =/  run=(unit ?)  (~(get by have) d)
    "%{(trip d)} ({?~(run "not started" ?:(u.run "running" "stopped"))})"
  =/  others=(list tape)
    %+  murn  ~(tap by have)
    |=  [d=dude:gall run=?]
    ?.  =(~ (find ~[d] bill))  ~
    `"%{(trip d)} ({?:(run "running" "stopped")}, not in its /desk/bill)"
  =/  all=(list tape)  (weld listed others)
  ?~  all  "none"
  (zing (join ", " `(list tape)`all))
--
