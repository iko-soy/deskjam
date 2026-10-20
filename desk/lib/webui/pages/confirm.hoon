/-  *deskjam
/+  sty=webui-styles, h=deskjam, par=webui-parts, dock=docket
|_  [=bowl:gall data msg=(unit [o=? =@t])]
+*  hc  ~(. h [our now]:bowl)
++  page
  ^-  manx
  ;html(lang "en")
    ;head
      ;title: Deskjam: confirm
      ;meta(charset "utf-8");
      ;meta
        =name     "viewport"
        =content  "width=device-width, initial-scale=1";
      ;style: {global:sty}
    ==
    ;body
      ;+  icons:par
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
          =*  up  u.staged
          =/  pack=mapp  (with-glob:hc u.dest stage-mapp.up glob)
          (view u.dest up (make-plan:hc u.dest stage-desk.up pack))
    ==
  ==
::
::  +view: what the commit would do, and a button to do it
::
++  view
  |=  [[=mode =desk] [when=time from=desk =mapp] pan=plan]
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
    ;*  (glob-box [mode desk] mapp pan)
    ;*  ?^  errors.pan  ~
        :_  ~
        ::  explicit, as the glob form's errors show this page at its url
        ::
        ;form(method "post", action "/apps/deskjam/confirm")
          ::  what this page shows, so a stale page can't commit
          ::  something else
          ::
          ;input(type "hidden", name "mode", value (trip mode.pan));
          ;input(type "hidden", name "desk", value (trip desk.pan));
          ;input(type "hidden", name "upload", value (scow %da when));
          ;input(type "hidden", name "rev", value (a-co:co rev.pan));
          ;input(type "hidden", name "glob", value ?~(glob "" (scow %uv u.glob)));
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
  %+  weld
    ^-  marl
    :_  ~
    ;p: {nom} is at revision {(a-co:co rev.pan)} and is {(zest-tape:hc zest.pan)}{has}.
  ^-  marl
  ::  a copy to undo the update with
  ::
  ?:  =(0 rev.pan)  ~
  =/  link=manx
    ;a(href "/apps/deskjam/download?desk={(trip desk.pan)}"): download {nom} as it is now
  :_  ~
  ?:  |(=(%base desk.pan) =(%kids desk.pan))
    ;p
      ; You can first
      ;+  link
      ;+  ;/  ", but deskjam won't replace {nom}, so it can't put that copy back for you."
    ==
  ;p
    ; To be able to undo this, first
    ;+  link
    ; . Uploading that copy and choosing Replace puts it back. That usually fails safely when the update changed the state an agent keeps, as the old agent can't load it, and Clay refuses the commit; but an agent that starts afresh from state it can't read, as deskjam does, loses that state instead. If the update changed the hash of a glob your ship serves, also upload the old frontend at /docket/upload.
  ==
::
::  +glob-box: the app's glob, and the option to serve it from our ship
::
::    a glob is an app's web frontend, which landscape's %docket agent
::    fetches as the desk's docket says. when the docket says our ship
::    serves it, its hash has to match the glob %docket holds, or the
::    app has no frontend. the hash changes with every frontend build,
::    so setting it here saves keeping it in the app's repo.
::
++  glob-box
  |=  [[=mode =desk] =mapp pan=plan]
  ^-  marl
  =/  up=(unit glob-reference:dock)
    (glob-ref:hc (upload-docket:hc [mode desk] mapp))
  ?~  up  ~
  =/  now=(unit glob-reference:dock)
    ?.  exists.pan  ~
    (glob-ref:hc (biff (desk-page:hc desk /desk/docket-0) read-docket:hc))
  ::  offer the hash of the glob our ship serves now, if it does
  ::
  =/  fill=@uvH  ?:((served-here:hc now) hash:(need now) hash.u.up)
  :_  ~
  ;div.box
    ;p: This app's web frontend is a glob, which its docket says to fetch {(glob-tape:hc u.up)}.
    ;+  ?^  glob
          ;form(method "post", action "/apps/deskjam/glob")
            ;p: deskjam will set the docket to have this ship serve it, with hash {(scow %uv u.glob)}.
            ;button(type "submit", name "clear", value "y"): leave the docket as uploaded
          ==
        ;form(method "post", action "/apps/deskjam/glob")
          ;label
            ; serve it from this ship instead, with hash
            ;input
              =type        "text"
              =name        "hash"
              =value       (scow %uv fill)
              =size        "40"
              =required    "required"
              =aria-label  "glob hash";
          ==
          ;button(type "submit", name "set", value "y"): set
        ==
    ;p
      ; Setting the hash reloads this page, which clears the boxes below, so set it first. It writes the hash into the desk's docket here, so the app's repo doesn't need it. Your ship's %docket then serves the glob with that hash, to you and to ships that install the app from you. If your ship doesn't have that glob yet, upload it at
      ;a/"/docket/upload": /docket/upload
      ;+  ;/  " once the app is running."
    ==
  ==
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
    =/  from=tape  "{(weld "%" (trip sud))} on {(scow %p her)}"
    =/  back=tape
      =/  as=tape  ?:(=(sud desk.pan) "" ", =local {nom}")
      "|install {(scow %p her)} {(weld "%" (trip sud))}{as}"
    :~  ;label
          ;input(type "checkbox", name "pause", value "y");
          ; stop kiln syncing {nom} from {from} (|pause {nom})
        ==
        ;p: That stops every update from {from}, not just the next one, and kiln forgets where {nom} came from. To get their updates again, run {back}, which replaces your upload with their latest release.
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
  =/  [shown=(list path) more=@ud]  (display-paths:hc ~(tap in pax))
  =/  rows=marl  (tree:par desk.pan (files-to-hierarchy:hc shown))
  :-  ~
  ?.  open
    ;details
      ;summary: {sum}
      ;table
        ;*  rows
      ==
      ;*  (more:par more)
    ==
  ;details(open "open")
    ;summary: {sum}
    ;table
      ;*  rows
    ==
    ;*  (more:par more)
  ==
--
