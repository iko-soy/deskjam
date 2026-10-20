/-  *deskjam
/+  sty=webui-styles, h=deskjam, par=webui-parts
|_  [=bowl:gall data msg=(unit [o=? =@t])]
+*  hc  ~(. h [our now]:bowl)
++  page
  ^-  manx
  ;html(lang "en")
    ;head
      ;title: Deskjam: choose where the upload goes
      ;meta(charset "utf-8");
      ;meta
        =name     "viewport"
        =content  "width=device-width, initial-scale=1";
      ;*  ?.  &(?=(~ staged) ?=([~ * * ~] fetching))  ~
          ?.  (waiting u.fetching)  ~
          ::  check back while a url upload is in progress
          ::
          :_  ~
          ;meta(http-equiv "refresh", content "2");
      ;style: {global:sty}
    ==
    ;body
      ;+  icons:par
      ;a/"/apps/deskjam": return home
      ;*  (banner:par msg)
      ;+  ?^  staged  (choose u.staged)
          ?~  fetching
            ?^  msg  ;div;
            ;p: Nothing is staged. Upload a deskjam first.
          ?^  err.u.fetching
            ;p.bad: Couldn't upload {(trip url.u.fetching)}: {(trip u.err.u.fetching)}
          ?.  (waiting u.fetching)
            ;p.bad: The fetch of {(trip url.u.fetching)} never finished. Go home and try again.
          ;p: Fetching {(trip url.u.fetching)}...
    ==
  ==
::
::  +waiting: whether a fetch could still answer
::
::    the thread gives up after ten minutes, but its answer can still
::    get lost, as when a kernel update suspends deskjam meanwhile
::
++  waiting
  |=  [id=@da url=@t err=(unit @t)]
  ^-  ?
  &(?=(~ err) (lth now.bowl (add id ~m11)))
::
::  +choose: describe the upload, and ask where it should go
::
++  choose
  |=  [time from=desk =mapp]
  ^-  manx
  =/  kel  (biff (~(get by mapp) /sys/kelvin) read-kelvins:hc)
  =/  duz  (biff (~(get by mapp) /desk/bill) read-dudes:hc)
  =/  doc  (biff (~(get by mapp) /desk/docket-0) read-docket:hc)
  =/  have=(list desk)  (sort ~(tap in desks:hc) aor)
  =/  exists=?  !=(~ (find ~[from] have))
  ::  desks kiln overwrites from elsewhere
  ::
  =/  syns  syncs:hc
  =/  label
    |=  d=desk
    ^-  tape
    =/  syn  (~(get ja syns) d)
    ?~  syn  (trip d)
    "{(trip d)} (synced from {(scow %p her.i.syn)})"
  ;div
    ;h1: {(weld "%" (trip from))}
    ;table
      ;tr
        ;td: app
        ;td
          ; {?~(doc "-" "{(trip title.u.doc)} {(version-tape:hc version.u.doc)}")}
        ==
      ==
      ;tr
        ;td: files
        ;td: {(a-co:co ~(wyt by mapp))}
      ==
      ;tr
        ;td: kernel
        ;td: {(kelvin-note kel)}
      ==
      ;tr
        ;td: agents
        ;td: {?:(|(?=(~ duz) ?=([~ ~] duz)) "none" (dudes-tape:hc (need duz)))}
      ==
    ==
    ;br;
    ;div.box
      ;p: Update an existing desk:
      ;form(method "post")
        ;select(name "desk", required "required", aria-label "desk to update")
          ;*  ?:  exists  ~
              :_  ~
              ;option(value "", disabled "disabled", selected "selected"): choose a desk
          ;*  %+  turn  have
              |=  d=desk
              ^-  manx
              ?:  =(d from)
                ;option(value (trip d), selected "selected"): {(label d)}
              ;option(value (trip d)): {(label d)}
        ==
        ;*  =/  syn  (~(get ja syns) from)
            ?~  syn  ~
            =/  stop=tape
              ?^(via.i.syn "" ", unless you stop the sync on the next page")
            :_  ~
            ;p.bad: Careful: {(weld "%" (trip from))} is overwritten from outside ({(sync-tape:hc i.syn)}), so its next update will undo an upload here{stop}.
        ;br;
        ;label
          ;input(type "radio", name "mode", value "m", checked "checked");
          ; merge into it: add and overwrite files, and keep the rest
        ==
        ;br;
        ;label
          ;input(type "radio", name "mode", value "r");
          ; replace it: make the desk exactly this upload, deleting files the upload lacks
        ==
        ;br;
        ;button(type "submit"): next
      ==
    ==
    ;br;
    ;div.box
      ;p: Install it as a new desk:
      ;form(method "post")
        ;input(type "hidden", name "mode", value "n");
        ;input
          =type        "text"
          =name        "desk"
          =value       ?:(exists "" (trip from))
          =required    "required"
          =pattern     "[a-z][a-z0-9\\-]*"
          =aria-label  "new desk name"
          =size        "16";
        ;button(type "submit"): next
      ==
    ==
    ;h2: files
    ;*  =/  [shown=(list path) more=@ud]
          (display-paths:hc ~(tap in ~(key by mapp)))
        :-  ;table
              ;*  (tree:par from (files-to-hierarchy:hc shown))
            ==
        (more:par more)
  ==
::
::  +kelvin-note: which kernels the upload is for, and whether that's us
::
++  kelvin-note
  |=  kel=(unit (set weft))
  ^-  tape
  ?~  kel  "unknown: the upload has no /sys/kelvin that deskjam can read"
  =/  ours  "[%zuse {(a-co:co zuse)}]"
  =/  tag=tape
    ?-  (kelvin-fate:hc u.kel)
      %ok    "this ship runs {ours}"
      %old   "older than this ship's {ours}"
      %wait  "newer than this ship's {ours}"
      %drop  "unusable on this ship's {ours}"
    ==
  "{(wefts-tape:hc u.kel)} ({tag})"
--
