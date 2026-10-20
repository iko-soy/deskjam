/-  *deskjam
/+  sty=webui-styles, h=deskjam, par=webui-parts, dock=docket
|_  [=bowl:gall data msg=(unit [o=? =@t])]
+*  hc  ~(. h [our now]:bowl)
++  page
  ^-  manx
  ;html
    ;head
      ;title: Deskjam
      ;meta(charset "utf-8");
      ;meta
        =name     "viewport"
        =content  "width=device-width, initial-scale=1";
      ;style: {global:sty}
    ==
    ;body
      ;a/"/apps/deskjam": return home
      ;*  (banner:par msg)
      ;+  ?~  staged
            ?^  msg  ;div;
            ?^  sent
              =/  dex=tape  (trip desk.u.sent)
              ;p
                ; The upload was committed to {(weld "%" dex)}:
                ;a(href "/apps/deskjam/status?desk={dex}"): see its status
                ; .
              ==
            ;p: Nothing is staged. Upload a deskjam first.
          ?~  dest
            ;p: Choose a desk for the upload first.
          (view u.staged (make-plan:hc u.dest [stage-desk stage-mapp]:u.staged))
    ==
  ==
::
::  +view: what the commit would do, and a button to do it
::
++  view
  |=  [[when=time from=desk =mapp] pan=plan]
  ^-  manx
  =/  nom=tape  "%{(trip desk.pan)}"
  =/  title=tape
    ?-  mode.pan
      %n  "install %{(trip from)} as the new desk {nom}"
      %r  "replace {nom} with %{(trip from)}"
      %m  "merge %{(trip from)} into {nom}"
    ==
  ;div
    ;h1: {title}
    ;*  (about mapp pan)
    ;*  ?~  errors.pan  ~
        :_  ~
        ;div.errors
          ;p: deskjam can't do this:
          ;ul
            ;*  %+  turn  errors.pan
                |=  e=@t
                ^-  manx
                ;li: {(trip e)}
          ==
        ==
    ;*  ?~  warnings.pan  ~
        :_  ~
        ;div.warnings
          ;p: {?~(errors.pan "Before you confirm:" "Also:")}
          ;ul
            ;*  %+  turn  warnings.pan
                |=  w=@t
                ^-  manx
                ;li: {(trip w)}
          ==
        ==
    ;*  ?^  errors.pan  ~
        :_  ~
        ;form(method "post")
          ::  what this page shows, so a stale page can't commit
          ::  something else
          ::
          ;input(type "hidden", name "mode", value (trip mode.pan));
          ;input(type "hidden", name "desk", value (trip desk.pan));
          ;input(type "hidden", name "upload", value (scow %da when));
          ;*  (options pan)
          ;button(type "submit", name "commit", value "y"): confirm
        ==
    ;*  (files pan)
  ==
::
::  +about: the app being uploaded, and the desk it's going to
::
++  about
  |=  [=mapp pan=plan]
  ^-  marl
  =/  nom=tape  "%{(trip desk.pan)}"
  =/  app
    |=  doc=(unit docket:dock)
    ^-  tape
    ?~  doc  ""
    "{(trip title.u.doc)} {(version-tape:hc version.u.doc)}"
  =/  new=tape
    (app (biff (~(get by mapp) /desk/docket-0) read-docket:hc))
  =/  old=tape
    ?.  exists.pan  ""
    (app (biff (desk-page:hc desk.pan /desk/docket-0) read-docket:hc))
  %+  weld
    ^-  marl
    ?:  =("" new)  ~
    :_  ~
    ;p: The upload is {new}.
  ^-  marl
  ?.  exists.pan  ~
  =/  has=tape  ?:(=("" old) "" ", with {old} installed")
  :_  ~
  ;p: {nom} is at revision {(a-co:co rev.pan)} and is {(zest-tape:hc zest.pan)}{has}.
::
::  +options: whether to start the desk, and to stop kiln syncing it
::
++  options
  |=  pan=plan
  ^-  marl
  =/  nom=tape  "%{(trip desk.pan)}"
  =/  changes=?
    |(!=(~ adds.pan) !=(~ puts.pan) !=(~ dels.pan) !=(~ maybe.pan))
  =/  start=marl
    ?:  held.pan
      ::  for %base, the kernel warning says what happens
      ::
      ?:  =(%base desk.pan)  ~
      :_  ~
      ?:  ?=(%n mode.pan)
        ;p: Clay will create {nom} as an empty desk, and hold this upload.
      ;p: Clay will hold this upload until your ship runs a kernel it supports, so nothing changes now.
    ?:  live.pan
      :_  ~
      ?:  ?=(%held zest.pan)
        ;p: {nom} is suspended until its next update, so Clay will start it in a separate step after this commit. If that fails, the new files stay and {nom} stays suspended.
      ?.  changes
        ;p: {nom} is running, and nothing in it changes, so nothing reloads.
      ;p: {nom} is running, so Clay rebuilds its agents as part of this commit and reloads those whose code changed.
    ?^  revive.pan
      :_  ~
      ;p: {nom} won't be started: {(trip u.revive.pan)}.
    =/  what=tape
      ?~  agents.pan
        "mark it running after uploading (|revive {nom}); it has no agents"
      "start its agents after uploading (|revive {nom})"
    :~  ;label
          ;input(type "checkbox", name "revive", value "y");
          ; {what}
        ==
        ;br;
    ==
  =/  stop=marl
    ?~  source.pan  ~
    =*  sud  desk.u.source.pan
    =*  her  ship.u.source.pan
    :~  ;label
          ;input(type "checkbox", name "pause", value "y");
          ; stop kiln syncing {nom} from {(weld "%" (trip sud))} on {(scow %p her)} (|pause {nom})
        ==
        ;br;
    ==
  ::  what Clay checks in the commit itself
  ::
  =/  note=marl
    ?:  held.pan  ~
    =/  why=tape
      "Your browser then shows an error page, and your ship's dojo shows why."
    :_  ~
    ?:  ?=(%live zest.pan)
      ;p: If a file or agent fails to build, or a running agent fails to load its state, Clay rejects the whole commit and nothing changes. {why} An agent new to the desk that crashes as it starts doesn't stop the commit; the dojo then shows 'gall: failed'.
    ?:  |(live.pan =(%kids desk.pan))
      ;p: If a file fails to build, Clay rejects the whole commit and nothing changes. {why}
    ;p: If a file fails to build, Clay rejects the whole commit and nothing changes. {why} Clay only builds the agents of {nom} when it starts: if you start it here and an agent fails to build or load, Clay rejects the commit too.
  :(weld start stop note)
::
::  +files: the files the commit adds, overwrites, deletes and keeps
::
++  files
  |=  pan=plan
  ^-  marl
  =/  lists=(list [open=? name=tape pax=(set path)])
    :~  [& "files to delete" dels.pan]
        [& "files to add" adds.pan]
        [& "files to change" puts.pan]
        [& "files that may change" maybe.pan]
        [| "files that stay the same" same.pan]
        [| "files left in place" keeps.pan]
    ==
  %+  murn  lists
  |=  [open=? name=tape pax=(set path)]
  ^-  (unit manx)
  ?:  =(~ pax)  ~
  =/  sum=tape  "{name} ({(a-co:co ~(wyt in pax))})"
  =/  rows=marl  (tree:par desk.pan (files-to-hierarchy:hc ~(tap in pax)))
  :-  ~
  ?.  open
    ;details
      ;summary: {sum}
      ;table
        ;*  rows
      ==
    ==
  ;details(open "open")
    ;summary: {sum}
    ;table
      ;*  rows
    ==
  ==
--
