/-  *deskjam
/+  webui, rudder, server, dbug, verb, default-agent,
    j=deskjam, ju=deskjam-url
::
/$  deskpack-0-to-mime  %deskpack-0  %mime
/$  deskjam-to-deskpack-0  %deskjam  %deskpack-0
::
|%
+$  state-1   [%1 data]
+$  card      card:agent:gall
--
::
=|  state-1
=*  state  -
::
%-  agent:dbug
%+  verb  |
^-  agent:gall
=<
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this %|) bowl)
    hc    ~(. +> bowl)
::
++  on-init
  ^-  (quip card _this)
  :_  this
  [%pass /eyre/connect %arvo %e %connect [~ /apps/[dap.bowl]] dap.bowl]~
::
++  on-save  !>(state)
::
++  on-load
  |=  ole=vase
  ^-  (quip card _this)
  ::  the state only holds an upload in progress, so start afresh from
  ::  any state we can't read
  ::
  ?~  old=(mole |.(!<(state-1 ole)))  `this
  `this(state u.old)
::
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  ?+    mark  (on-poke:def mark vase)
      %handle-http-request
    ?>  =(src our):bowl
    =+  !<([=eyre-id =inbound-request:eyre] vase)
    ?.  authenticated.inbound-request
      [(login-redirect:hc eyre-id) this]
    =/  ,request-line:server
      (parse-request-line:server url.request.inbound-request)
    :: download the jam file of a desk
    ::
    ?:  ?=([%apps %deskjam %download ~] site)
      =/  [=desk files=(list path)]
        %+  roll  args
        |=  [[k=@t v=@t] [=desk files=(list path)]]
        ?+  k  [desk files]
          %desk  [(need ((sand %tas) v)) files]
          %path  ?~  file=(rush v stap)
                   [desk files]
                 [desk [u.file files]]
        ==
      :_  this
      ?~  files
        (simple-deskjam:hc eyre-id desk)
      (simple-sub-deskjam:hc eyre-id desk files)
    :: visiting the index starts afresh
    ::
    =?  +.state  ?=([%apps %deskjam ~] site)  *data
    :: use rudder to serve pages
    ::
    =/  pages  make-pages:hc
    =;  out=(quip card data)
      [-.out this(+.state +.out)]
    %.  [bowl [eyre-id inbound-request] +.state]
    %:  (steer:rudder data action)
      pages
      (point:rudder /apps/[dap.bowl] & ~(key by pages))
      (fours:rudder +.state)
      |=  axn=action
      ^-  $@  brief:rudder
          [brief:rudder (list card) data]
      ?^  err=(reject:hc axn)  u.err
      =^  caz  this
        (on-poke %deskjam-action !>(axn))
      [(brief:hc axn) caz +.state]
    ==
    ::
      %deskjam-action
    ?>  =(src our):bowl
    =/  axn  !<(action vase)
    ?^  err=(reject:hc axn)
      (mean leaf+(trip u.err) ~)
    ?-    -.axn
        %stage-mapp
      `this(staged `[now.bowl [desk mapp]:axn], fetching ~)
      ::
        %url-thread
      =/  url=@t  (unfrag:jc:hc url.axn)
      :_  this(staged ~, fetching `[now.bowl url ~])
      ~[(url-thread-card:hc now.bowl url)]
      ::
        %set-dest
      `this(dest `[mode desk]:axn)
      ::
        ?(%commit %new-desk %add-files)
      =/  [revive=? pause=?]
        ?:(?=(%commit -.axn) [revive pause]:axn [| |])
      =/  pan=plan  current-plan:hc
      =/  caz=(list card)  (commit-cards:hc pan revive pause)
      =.  sent  `[desk.pan rev.pan held.pan |(live.pan revive)]
      ::  the older pokes kept the upload staged, so keep doing that
      ::
      =?  +.state  ?=(%commit -.axn)  +.state(staged ~, dest ~)
      [caz this]
    ==
  ==
::
++  on-watch
  |=  =path
  ^-  (quip card _this)
  ?>  =(our.bowl src.bowl)
  ?+  path  (on-watch:def path)
    [%http-response *]  [~ this]
  ==
::
++  on-agent  on-agent:def
++  on-peek   on-peek:def
::
++  on-arvo
  |=  [=wire =sign-arvo]
  ^-  (quip card _this)
  ?+    wire  (on-arvo:def wire sign-arvo)
      [%eyre %connect ~]
    ?>  ?=([%eyre %bound *] sign-arvo)
    ~?  !accepted.sign-arvo
      [dap.bowl 'eyre bind rejected!' binding.sign-arvo]
    [~ this]
    ::
      [?(%new-desk %put-files %revive) *]
    ::  clay doesn't answer these, but don't crash if it ever does
    ::
    [~ this]
    ::
      [%url-thread ~]
    ::  a fetch started by an older version of deskjam
    ::
    [~ this]
    ::
      [%url-thread @ ~]
    ?>  ?=([%khan %arow *] sign-arvo)
    ::  ignore fetches the user has since moved on from
    ::
    =/  id=@da  (slav %da i.t.wire)
    ?.  &(?=(^ fetching) =(id id.u.fetching))
      [~ this]
    =*  url  url.u.fetching
    ?:  ?=(%| -.p.sign-arvo)
      ::  a failed thread's tang starts with its error term
      ::
      =*  gof  p.p.sign-arvo
      =/  tan=tang  tang.gof
      =/  cause=(unit @t)
        ?.  &(?=(%thread-fail mote.gof) ?=([@ *] tan))  ~
        `i.tan
      =?  tan  ?=(^ cause)  ?>(?=(^ tan) t.tan)
      =/  why=@t
        ?^  tan  (crip (zing (join "; " (turn tan |=(=tank ~(ram re tank))))))
        ?~  cause  mote.gof
        ?:  =(%cancelled u.cause)  'the fetch was stopped; try again'
        u.cause
      [~ this(fetching `[id url `why])]
    =/  pack=(unit deskpack)
      (mole |.((deskjam-to-deskpack-0 !<(@ q.p.p.sign-arvo))))
    ?~  pack
      [~ this(fetching `[id url `'it isn\'t a deskjam'])]
    [~ this(staged `[now.bowl u.pack], fetching ~)]
  ==
::
++  on-leave  on-leave:def
++  on-fail   on-fail:def
--
|_  =bowl:gall
++  sour  (scot %p our.bowl)
++  snow  (scot %da now.bowl)
++  jc  ~(. j [our now]:bowl)
::
::  +current-plan: what committing the staged upload to .dest would do
::
++  current-plan
  ^-  plan
  ?>  ?=(^ staged)
  ?>  ?=(^ dest)
  (make-plan:jc u.dest [stage-desk stage-mapp]:u.staged)
::
::  +reject: why an action can't be done, if it can't
::
++  reject
  |=  axn=action
  ^-  (unit @t)
  ?-    -.axn
      %stage-mapp  ~
  ::
      %url-thread
    ::  iris never answers a url it can't parse
    ::
    ?~  out=(sendable:ju url.axn)
      `'Give an http or https url.'
    ~
  ::
  ::  any dest may be set, as before; the web form checks it, and the
  ::  commit checks the plan
  ::
      %set-dest  ~
  ::
      ?(%commit %new-desk %add-files)
    ?~  staged
      ?~  sent  `'Nothing is staged. Upload a deskjam first.'
      %-  some
      %-  crip
      "The upload was committed to %{(trip desk.u.sent)}. Upload a deskjam to commit another."
    ?~  dest  `'Choose a desk for the upload first.'
    ?:  &(?=(%new-desk -.axn) !?=(%n mode.u.dest))
      `'%new-desk needs a new desk as the destination.'
    ?:  &(?=(%add-files -.axn) !?=(%m mode.u.dest))
      `'%add-files needs a desk to merge into as the destination.'
    =/  pan=plan  current-plan
    ?^  errors.pan  `i.errors.pan
    ?:  &(?=(%commit -.axn) revive.axn !live.pan ?=(^ revive.pan))
      `(crip "%{(trip desk.pan)} can't be started: {(trip u.revive.pan)}.")
    ~
  ==
::
::  +brief: what to tell the user an action did
::
++  brief
  |=  axn=action
  ^-  brief:rudder
  ?+  -.axn  ~
    %stage-mapp  'Upload staged.'
  ==
::
::  +commit-cards: commit the staged upload as .pan says
::
::    one clay commit, so a build failure aborts all of it. reviving in
::    the same event means agents that fail to start abort it too.
::
++  commit-cards
  |=  [pan=plan revive=? pause=?]
  ^-  (list card)
  ?>  ?=(^ staged)
  =*  mapp  stage-mapp.u.staged
  =/  stop=(list card)
    ?.  &(pause ?=(^ source.pan))  ~
    :_  ~
    :*  %pass  /pause/[desk.pan]  %agent  [our.bowl %hood]
        %poke  %kiln-pause  !>(desk.pan)
    ==
  =/  commit=(list card)
    ?:  ?=(%n mode.pan)
      [%pass /new-desk/[desk.pan] %arvo (new-desk:cloy desk.pan ~ mapp)]~
    ::  leave out files we know are unchanged: the commit is the same
    ::  without them, and unchanged /sys files would set off a kernel
    ::  update on %base
    ::
    =/  =soba:clay
      %+  weld
        ^-  soba:clay
        (turn ~(tap in dels.pan) |=(=path [path %del ~]))
      ^-  soba:clay
      %+  murn  ~(tap by mapp)
      |=  [=path =page:clay]
      ^-  (unit [^path miso:clay])
      ?:  &((~(has in same.pan) path) exact:(stored-lobes:jc path page))
        ~
      ?:  (~(has in adds.pan) path)
        `[path %ins p.page !>(q.page)]
      `[path %mut p.page !>(q.page)]
    ?~  soba  ~
    [%pass /put-files/[desk.pan] %arvo %c %info desk.pan %& soba]~
  =/  start=(list card)
    ?.  &(revive !live.pan)  ~
    [%pass /revive/[desk.pan] %arvo %c %zest desk.pan %live]~
  :(weld stop commit start)
::
++  url-thread-card
  |=  [id=@da url=@t]
  ^-  card
  :*  %pass  /url-thread/(scot %da id)  %arvo  %k  %fard
      q.byk.bowl  %deskjam-url  %noun
      !>((some url))
  ==
::
++  page-paths
  ^-  (list path)
  ~[/index /staged /confirm /subset /status]
::
++  make-pages
  %-  ~(gas by *(map @ta (page:rudder data action)))
  (turn page-paths make-page:webui)
::
++  en-mapp
  |=  [=desk files=(list path)]
  ^-  mapp
  =+  .^(=domo:clay %cv /[sour]/[desk]/[snow])
  =/  commit=@ud  ud:.^(cass:clay %cw /[sour]/[desk]/[snow])
  =/  =tako:clay  (~(got by hit.domo) commit)
  =+  .^(=yaki:clay %cs /[sour]/base/[snow]/yaki/(scot %uv tako))
  =+  .^(=rang:clay %cx /[sour]//[snow]/rang)
  %-  ~(gas by *mapp)
  %+  turn  files
  |=  file=path
  ^-  (pair path page:clay)
  ~|  [%missing-source-file /[sour]/[desk]/[snow] file]
  :-  file
  (~(got by lat.rang) (~(got by q.yaki) file))
::
++  en-mapp-full
  |=(=desk (en-mapp desk ~(tap in (desk-files desk))))
::
++  en-mapp-part
  |=  [=desk files=(list path)]
  =/  desk-files=(set path)  (desk-files desk)
  %+  en-mapp  desk
  %+  murn  files
  |=  file=path
  ?.((~(has in desk-files) file) ~ (some file))
::
++  desk-files
  |=  =desk
  ^-  (set path)
  %-  ~(gas in *(set path))
  .^((list path) %ct /[sour]/[desk]/[snow])
::
++  desk-to-mime
  |=  =desk
  ^-  mime
  %-  deskpack-0-to-mime
  [desk (en-mapp-full desk)]
::
++  subdesk-to-mime
  |=  [=desk files=(list path)]
  ^-  mime
  %-  deskpack-0-to-mime
  [desk (en-mapp-part desk files)]
::
++  simple-deskjam
  |=  [=eyre-id =desk]
  ^-  (list card)
  =/  jamm  (desk-to-mime desk)
  %+  give-simple-payload:app:server  eyre-id
  :_  [~ q.jamm]
  :-  200
  :~  ['content-type' (en-mite:mimes:html p.jamm)]
      :-  'Content-Disposition'
      %-  crip
      "attachment; filename=\"{(trip desk)}.deskjam\""
  ==
::
++  simple-sub-deskjam
  |=  [=eyre-id =desk files=(list path)]
  ^-  (list card)
  =/  jamm  (subdesk-to-mime desk files)
  %+  give-simple-payload:app:server  eyre-id
  :_  [~ q.jamm]
  :-  200
  :~  ['content-type' (en-mite:mimes:html p.jamm)]
      :-  'Content-Disposition'
      %-  crip
      "attachment; filename=\"{(trip desk)}-subset.deskjam\""
  ==
::
++  login-redirect
  |=  =eyre-id
  ^-  (list card)
  %+  give-simple-payload:app:server  eyre-id
  [[307 ['Location' '/~/login?redirect=%2Fapps%2Fdeskjam'] ~] ~]
--
