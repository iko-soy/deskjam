/-  *deskjam, spider
/+  webui, rudder, server, dbug, default-agent,
    j=deskjam, ju=deskjam-url
::
/$  deskpack-0-to-mime  %deskpack-0  %mime
::
|%
+$  state-2   [%2 data]
+$  state-1   [%1 data-1]
+$  card      card:agent:gall
--
::
=|  state-2
=*  state  -
::
::  no verb wrapper: it takes /verb/events subscriptions from any ship
::  before +on-watch can check them, then sends them every event
::
%-  agent:dbug
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
  ::  end any subscriptions to the event streams the verb wrapper served
  ::
  =/  kick=(list card)
    [%give %kick ~[/verb/events /verb/events-plus] ~]~
  ::  the state only holds an upload in progress, so start afresh from
  ::  any state we can't read
  ::
  ?^  new=(mole |.(!<(state-2 ole)))  [kick this(state u.new)]
  ?~  old=(mole |.(!<(state-1 ole)))  [kick this]
  =*  d  +.u.old
  [kick this(state [%2 staged.d dest.d fetching.d sent.d ~])]
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
    ?^  why=(cross-site:ju request.inbound-request)
      [(refuse-cross-site:hc eyre-id u.why) this]
    =/  ,request-line:server
      (parse-request-line:server url.request.inbound-request)
    :: download the jam file of a desk
    ::
    ?:  ?=([%apps %deskjam %download ~] site)
      =/  [dex=(unit desk) files=(list path)]
        %+  roll  args
        |=  [[k=@t v=@t] [dex=(unit desk) files=(list path)]]
        ?+  k  [dex files]
          %desk  [?:(=('' v) ~ ((sand %tas) v)) files]
          %path  ?~  file=(rush v stap)
                   [dex files]
                 [dex [u.file files]]
        ==
      :_  this
      ?~  dex
        (no-download:hc eyre-id "Give a desk to download, as ?desk=name.")
      ?.  (has-files:jc:hc u.dex)
        %+  no-download:hc  eyre-id
        "There is no desk called %{(trip u.dex)} with files to download."
      ?~  files
        (simple-deskjam:hc eyre-id u.dex)
      (simple-sub-deskjam:hc eyre-id u.dex files)
    ::  visiting the index starts afresh, unless the browser says
    ::  another site sent it here: such a link could lose your upload
    ::
    =/  fresh=?
      ?&  ?=([%apps %deskjam ~] site)
          !(cross-site-get:ju request.inbound-request)
      ==
    =/  stop=(list card)  ?.(fresh ~ stop-fetch:hc)
    =?  +.state  fresh  *data
    :: use rudder to serve pages
    ::
    =/  pages  make-pages:hc
    =;  out=(quip card data)
      [(weld stop -.out) this(+.state +.out)]
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
      :-  stop-fetch:hc
      this(staged `[now.bowl [desk mapp]:axn], fetching ~, glob ~)
      ::
        ?(%url-thread %fetch)
      =/  [url=@t local=?]
        ?-(-.axn %url-thread [url.axn |], %fetch [url local]:axn)
      =.  url  (unfrag:jc:hc url)
      :_  this(staged ~, fetching `[now.bowl url ~], glob ~)
      (weld stop-fetch:hc (fetch-cards:hc now.bowl url local))
      ::
        %set-dest
      `this(dest `[mode desk]:axn, glob ~)
      ::
        %set-glob
      `this(glob hash.axn)
      ::
        ?(%commit %new-desk %add-files)
      =/  [revive=? pause=?]
        ?:(?=(%commit -.axn) [revive pause]:axn [| |])
      =/  pan=plan  current-plan:hc
      =/  caz=(list card)  (commit-cards:hc pan revive pause)
      =.  sent  `[desk.pan rev.pan held.pan |(live.pan revive)]
      ::  the older pokes kept the upload staged, so keep doing that
      ::
      =?  +.state  ?=(%commit -.axn)  +.state(staged ~, dest ~, glob ~)
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
++  on-agent
  |=  [=wire =sign:agent:gall]
  ^-  (quip card _this)
  ?+    wire  (on-agent:def wire sign)
      [%fetch-stop @ ~]
    ::  spider refuses to stop a fetch that already ended
    ::
    [~ this]
    ::
      [%fetch @ ~]
    ::  ignore fetches the user has since moved on from
    ::
    =/  id=@da  (slav %da i.t.wire)
    ?.  &(?=(^ fetching) =(id id.u.fetching) ?=(~ err.u.fetching))
      [~ this]
    =*  url  url.u.fetching
    =/  fail  |=(why=@t [~ this(fetching `[id url `why])])
    ?-    -.sign
        %kick  [~ this]
    ::
        %poke-ack
      ?~  p.sign  [~ this]
      (fail 'the fetch couldn\'t start')
    ::
        %watch-ack
      ?~  p.sign  [~ this]
      (fail 'the fetch couldn\'t start')
    ::
        %fact
      ?+    p.cage.sign  [~ this]
          %thread-fail
        =+  !<([=term =tang] q.cage.sign)
        (fail (fetch-why:hc term tang))
      ::
          %thread-done
        [~ this(+.state (took-fetch:hc id url !<(@ q.cage.sign)))]
      ==
    ==
  ==
::
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
    ::  a fetch started with khan by an older version of deskjam
    ::
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
      [~ this(fetching `[id url `(fetch-why:hc (fall cause mote.gof) tan)])]
    [~ this(+.state (took-fetch:hc id url !<(@ q.p.p.sign-arvo)))]
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
::  +staged-mapp: the staged upload, as the commit would write it
::
++  staged-mapp
  ^-  mapp
  ?>  ?=(^ staged)
  ?~  dest  stage-mapp.u.staged
  (with-glob:jc u.dest stage-mapp.u.staged glob)
::
::  +current-plan: what committing the staged upload to .dest would do
::
++  current-plan
  ^-  plan
  ?>  ?=(^ staged)
  ?>  ?=(^ dest)
  (make-plan:jc u.dest stage-desk.u.staged staged-mapp)
::
::  +reject: why an action can't be done, if it can't
::
++  reject
  |=  axn=action
  ^-  (unit @t)
  ?-    -.axn
      %stage-mapp  ~
  ::
      ?(%url-thread %fetch)
    =/  [url=@t local=?]
      ?-(-.axn %url-thread [url.axn |], %fetch [url local]:axn)
    ::  iris never answers a url it can't parse
    ::
    ?~  (sendable:ju url)
      `'Give an http or https url.'
    ?:  &(!local (local:ju url))
      `'That url is on this machine or your local network. To fetch it anyway, tick "allow local addresses".'
    ~
  ::
  ::  any dest may be set, as before; the web form checks it, and the
  ::  commit checks the plan
  ::
      %set-dest  ~
  ::
      %set-glob
    ?~  staged  `'Nothing is staged. Upload a deskjam first.'
    ?~  dest  `'Choose a desk for the upload first.'
    ?~  hash.axn  ~
    ?~  (serve-glob:jc u.dest stage-mapp.u.staged u.hash.axn)
      `'The docket the desk would have has no glob to serve.'
    ~
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
  =/  pack=mapp  staged-mapp
  =/  stop=(list card)
    ?.  &(pause ?=(^ source.pan))  ~
    :_  ~
    :*  %pass  /pause/[desk.pan]  %agent  [our.bowl %hood]
        %poke  %kiln-pause  !>(desk.pan)
    ==
  =/  commit=(list card)
    ?:  ?=(%n mode.pan)
      [%pass /new-desk/[desk.pan] %arvo (new-desk:cloy desk.pan ~ pack)]~
    ::  leave out files we know are unchanged: the commit is the same
    ::  without them, and unchanged /sys files would set off a kernel
    ::  update on %base
    ::
    =/  =soba:clay
      %+  weld
        ^-  soba:clay
        (turn ~(tap in dels.pan) |=(=path [path %del ~]))
      ^-  soba:clay
      %+  murn  ~(tap by pack)
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
::  url uploads
::
::    a thread fetches the url, following redirects. spider runs it, not
::    khan, so that deskjam can stop it when the user moves on.
::
::  +fetch-tid: the thread id of the fetch started at .id
::
++  fetch-tid
  |=  id=@da
  ^-  @ta
  (cat 3 'deskjam-url--' (scot %ud id))
::
::  +fetch-cards: start fetching .url, as the fetch started at .id
::
++  fetch-cards
  |=  [id=@da url=@t local=?]
  ^-  (list card)
  =/  tid=@ta  (fetch-tid id)
  =/  =wire  /fetch/(scot %da id)
  =/  args=start-args:spider
    [~ `tid byk.bowl(r da+now.bowl) %deskjam-url !>(`[url local])]
  :~  [%pass wire %agent [our.bowl %spider] %watch /thread-result/[tid]]
      [%pass wire %agent [our.bowl %spider] %poke %spider-start !>(args)]
  ==
::
::  +stop-fetch: stop the fetch in progress, if there is one
::
++  stop-fetch
  ^-  (list card)
  ?.  &(?=(^ fetching) ?=(~ err.u.fetching))  ~
  =*  id  id.u.fetching
  :~  [%pass /fetch/(scot %da id) %agent [our.bowl %spider] %leave ~]
      :*  %pass  /fetch-stop/(scot %da id)  %agent  [our.bowl %spider]
          %poke  %spider-stop  !>([(fetch-tid id) |])
      ==
  ==
::
::  +fetch-why: what a failed fetch's error says
::
++  fetch-why
  |=  [err=@t =tang]
  ^-  @t
  ?^  tang  (crip (zing (join "; " (turn tang |=(=tank ~(ram re tank))))))
  ?:  =('cancelled' err)  'the fetch was stopped; try again'
  err
::
::  +took-fetch: the state once the fetch started at .id got .dat
::
++  took-fetch
  |=  [id=@da url=@t dat=@]
  ^-  data
  =/  got  (unpack:jc dat)
  ?:  ?=(%| -.got)
    =/  why=@t
      ?-  p.got
          %not
        'it isn\'t a deskjam. Link to the file itself, not to a page about it'
      ::
          %bomb
        'it unpacks to far more than its size, as only a crafted file would, so deskjam won\'t read it'
      ==
    +.state(fetching `[id url `why])
  +.state(staged `[now.bowl p.got], fetching ~, glob ~)
::
++  page-paths
  ^-  (list path)
  ~[/index /staged /confirm /glob /subset /status]
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
::  +no-download: say why there's nothing to download
::
++  no-download
  |=  [=eyre-id why=tape]
  ^-  (list card)
  %+  give-simple-payload:app:server  eyre-id
  :-  :-  404
      :~  ['content-type' 'text/plain; charset=utf-8']
          ['x-content-type-options' 'nosniff']
      ==
  `(as-octs:mimes:html (crip why))
::
++  login-redirect
  |=  =eyre-id
  ^-  (list card)
  %+  give-simple-payload:app:server  eyre-id
  [[307 ['Location' '/~/login?redirect=%2Fapps%2Fdeskjam'] ~] ~]
::
::  +refuse-cross-site: answer a request +cross-site:ju refused, and why
::
++  refuse-cross-site
  |=  [=eyre-id why=tape]
  ^-  (list card)
  %+  give-simple-payload:app:server  eyre-id
  :-  :-  403
      :~  ['content-type' 'text/plain; charset=utf-8']
          ['x-content-type-options' 'nosniff']
      ==
  `(as-octs:mimes:html (crip why))
--
