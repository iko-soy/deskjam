/-  *deskjam
/+  multipart, dock=docket
|_  [our=ship now=time]
++  sour  (scot %p our)
++  snow  (scot %da now)
++  desks  .^((set desk) %cd /[sour]//[snow])
:: list to unit
::
++  lint
  |*  =(list)
  ^-  (unit _?>(?=(^ list) i.list))
  ~|  %cannot-convert-multiple-to-unit
  ?>  ?=(?(~ [* ~]) list)
  ?~(list ~ (some i.list))
::
++  grab
  |*  [=mold key=@t parts=(list [@t part:multipart])]
  %-  lint
  ^-  (list mold)
  %+  murn  parts
  |=  [n=@t p=part:multipart]
  ^-  (unit mold)
  ?.  =(key n)  ~
  [~ `mold`body:p]
::
++  desk-files  |=(=desk .^((list path) %ct /[sour]/[desk]/[snow]))
::
++  desk-to-hierarchy
  |=  =desk
  ^-  (list [pat=path dir=? dep=@])
  (files-to-hierarchy (desk-files desk))
::
++  file-to-ancestors
  |=  pat=path
  ^-  (list path)
  (path-to-ancestors pat |)
::
++  path-to-ancestors
  |=  [pat=path dir=?]
  ^-  (list path)
  =.  pat  (flop pat)
  =?  pat  !dir  ?>(?=([@ @ *] pat) t.t.pat)
  =|  out=(list path)
  |-
  ?~  pat  [/ out]
  $(pat t.pat, out [(flop pat) out])
::
++  path-to-classes
  |=  [pat=path dir=?]
  ^-  tape
  (zing (join " " (turn (path-to-ancestors pat dir) spud)))
::
++  files-to-hierarchy
  |=  pax=(list path)
  ^-  (list [pat=path dir=? dep=@])
  =|  out=(set [pat=path dir=? dep=@])
  |-
  ?~  pax  (sort ~(tap in out) aor)
  =/  new=(list [pat=path dir=? dep=@])
    :-  [i.pax | (sub (lent i.pax) 1)]
    %+  turn  (file-to-ancestors i.pax)
    |=(p=path [p & (lent p)])
  $(pax t.pax, out (~(gas in out) new))
::
::  desk state
::
::  +desk-exists: whether clay knows a desk, with or without commits
::
++  desk-exists  |=(=desk (~(has in desks) desk))
::
::  +domes: clay's state of every local desk
::
++  domes
  ^-  (map desk dome:clay)
  %-  ~(gas by *(map desk dome:clay))
  %+  murn  ~(tap by .^(cone:clay %cx /[sour]//[snow]/domes))
  |=  [[=ship =desk] =dome:clay]
  ?.(=(our ship) ~ `[desk dome])
::
::  +syncs: every desk kiln overwrites from elsewhere, and from where
::
::    a kiln sync (|install, |sync) merges each new revision of its
::    source into its desk, and then into its kids desk if it has one,
::    as with %base and %kids. .via is the desk a kids merge follows;
::    .auto is whether kiln merges updates without asking.
::
++  syncs
  ^-  (jar desk [her=ship sud=desk via=(unit desk) auto=?])
  =/  mer=?  .^(? %gx /[sour]/hood/[snow]/kiln/automerge/loob)
  =/  zyn
    ;;  (map [desk ship desk] [@ta (unit desk) @ud (unit ?) *])
    .^(* %gx /[sour]/hood/[snow]/kiln/syncs/noun)
  =|  out=(jar desk [her=ship sud=desk via=(unit desk) auto=?])
  =/  all  ~(tap by zyn)
  |-  ^+  out
  ?~  all  out
  =/  [[syd=desk her=ship sud=desk] [* kid=(unit desk) * nit=(unit ?) *]]
    i.all
  =/  auto=?  |(=(our her) ?~(nit mer u.nit))
  =.  out  (~(add ja out) syd [her sud ~ auto])
  =?  out  ?=(^ kid)  (~(add ja out) u.kid [her sud `syd auto])
  $(all t.all)
::
::  +sync-tape: where kiln overwrites a desk from
::
++  sync-tape
  |=  [her=ship sud=desk via=(unit desk) auto=?]
  ^-  tape
  =/  from=tape  "%{(trip sud)} on {(scow %p her)}"
  =/  how=tape  ?:(auto "" ", once you approve each update")
  ?~  via  "kiln syncs it from {from}{how}"
  "kiln copies {from} into it whenever it updates %{(trip u.via)}{how}"
::
::  +agents: a desk's agents, and whether each is running
::
++  agents
  |=  =desk
  ^-  (set [dude:gall ?])
  .^((set [dude:gall ?]) %ge /[sour]/[desk]/[snow]/$)
::
::  +desk-lobes: the lobe of every file in a desk's latest commit
::
++  desk-lobes
  |=  =desk
  ^-  (map path @uvI)
  =+  .^(=domo:clay %cv /[sour]/[desk]/[snow])
  ?:  =(0 let.domo)  ~
  =/  =tako:clay  (~(got by hit.domo) let.domo)
  q:.^(yaki:clay %cs /[sour]/[desk]/[snow]/yaki/(scot %uv tako))
::
::  +blob: a page from clay's store as it is, without building marks
::
++  blob
  |=  lob=@uvI
  ^-  page:clay
  .^(page:clay %cs /[sour]/base/[snow]/blob/(scot %uv lob))
::
::  +desk-page: a file of a desk, if it has the file
::
++  desk-page
  |=  [=desk =path]
  ^-  (unit page:clay)
  (bind (~(get by (desk-lobes desk)) path) blob)
::
::  reading special files
::
::    jammer and |commit produce %mime pages; deskjam's own downloads
::    hold pages of each file's own mark. read both kinds.
::
++  page-text
  |=  =page:clay
  ^-  (unit @t)
  ?.  ?=(%mime p.page)  ~
  (bind (mole |.(;;(mime q.page))) |=(=mime `@t`q.q.mime))
::
::  +read-kelvins: the kelvins of a /sys/kelvin page, as clay reads them
::
++  read-kelvins
  |=  =page:clay
  ^-  (unit (set weft))
  %-  mole  |.
  %-  waft-to-wefts:clay
  ?+  p.page  !!
    %kelvin  ;;(waft:clay q.page)
    %mime    (cord-to-waft:clay q.q:;;(mime q.page))
  ==
::
++  read-dudes
  |=  =page:clay
  ^-  (unit (list dude:gall))
  %-  mole  |.
  ?^  tex=(page-text page)
    !<((list dude:gall) (slap !>(~) (ream u.tex)))
  ;;((list dude:gall) q.page)
::
++  read-docket
  |=  =page:clay
  ^-  (unit docket:dock)
  %+  biff
    %-  mole  |.
    ^-  (unit docket:dock)
    ?^  tex=(page-text page)
      %-  from-clauses:mime:dock
      !<((list clause:dock) (slap !>(~) (ream u.tex)))
    `;;(docket:dock q.page)
  same
::
::  +kelvin-fate: what clay does with a commit listing these kelvins
::
::    on any desk but %base:
::      %ok: commits it
::      %old: commits it, but won't revive the desk with it
::      %wait: holds it until the ship upgrades to one of them
::      %drop: ignores it
::
++  kelvin-fate
  |=  kel=(set weft)
  ^-  ?(%ok %old %wait %drop)
  ?:  (~(has in kel) zuse+zuse)  %ok
  ?:  (~(any in kel) |=(=weft &(=(%zuse lal.weft) (gth num.weft zuse))))
    %old
  ?:  (~(all in kel) |=(=weft (gth num.weft zuse)))  %drop
  %wait
::
::  +base-fate: what clay does with a %base commit listing these kelvins
::
::      %ok: commits it
::      %now: commits it, changing the kernel at once
::      %wait: holds it until every essential running desk supports it
::      %drop: ignores it
::
++  base-fate
  |=  [kel=(set weft) doms=(map desk dome:clay)]
  ^-  ?(%ok %now %wait %drop)
  ?:  (~(has in kel) zuse+zuse)  %ok
  =/  ready=?
    %+  levy  ~(tap by doms)
    |=  [d=desk =dome:clay]
    ?|  =(%base d)
        !.^(? %cx /[sour]//[snow]/esse/[d])
        !?=(%live liv.dome)
        !=(~ (~(int in ~(key by wic.dome)) kel))
    ==
  ?:  ready  %now
  ?:  (~(all in kel) |=(=weft (gth num.weft zuse)))  %drop
  %wait
::
::  +override: apply a desk's rein to its bill, as clay does
::
++  override
  |=  [duz=(list dude:gall) ren=rein:clay]
  ^-  (list dude:gall)
  =/  out=(list dude:gall)  (skip duz ~(has by ren))
  (~(rep by ren) |=([[d=dude:gall r=?] =_out] ?.(r out [d out])))
::
::  +stored-lobes: the lobes clay could store for an uploaded file, and
::  whether that's exactly the lobe it will store
::
::    clay converts a %mime page to the file's mark and hashes the
::    result. for marks whose conversion we know, do the same. most
::    other marks keep the file's bytes, as an atom or as octs, so try
::    both: a stored lobe can only match one if the content is the same,
::    but matching neither doesn't mean the file changed.
::
++  stored-lobes
  |=  [pax=path pag=page:clay]
  ^-  [exact=? lobes=(list @uvI)]
  ?~  pax  [| ~]
  =/  mak=mark  (rear pax)
  ?.  ?=(%mime p.pag)
    ?.(=(mak p.pag) [| ~] [& ~[(page-to-lobe:clay pag)]])
  ?~  mim=(mole |.(;;(mime q.pag)))  [| ~]
  =*  oct  q.u.mim
  =/  one  |=(n=* `(list *)`~[n])
  =/  nats=(unit (list *))
    ?+  mak  ~
      %hoon      `~[q.oct]
      %txt       `~[(to-wain:format q.oct)]
      %json      `~[(fall (de:json:html q.oct) *json)]
      %kelvin    (bind (mole |.((cord-to-waft:clay q.oct))) one)
      %bill      (bind (read-dudes pag) one)
      %docket-0  (bind (read-docket pag) one)
    ==
  =/  lobe  |=(n=* (page-to-lobe:clay [mak n]))
  ?^  nats  [& (turn u.nats lobe)]
  [| (turn `(list *)`~[q.oct oct] lobe)]
::
::  +waiting: newer kernels with commits waiting on a desk, that a
::  commit listing .kel would leave waiting
::
::    clay drops waiting commits for kernels at or before ours, and a
::    commit replaces the waiting commits for the kernels it lists.
::
++  waiting
  |=  [=dome:clay kel=(set weft)]
  ^-  (set weft)
  %-  ~(dif in (silt (skim ~(tap in ~(key by wic.dome)) newer)))
  kel
::
++  newer  |=(=weft &(=(%zuse lal.weft) (lth num.weft zuse)))
::
::  +unfrag: a url without its #fragment, which http never sends
::
++  unfrag
  |=  url=@t
  ^-  @t
  =/  tex=tape  (trip url)
  (crip (scag (fall (find "#" tex) (lent tex)) tex))
::
::  rendering
::
++  plural
  |=  [n=@ud one=tape]
  ^-  tape
  "{(a-co:co n)} {one}{?:(=(1 n) "" "s")}"
::
++  wefts-tape
  |=  kel=(set weft)
  ^-  tape
  %-  zing
  %+  join  " "
  %+  turn
    (sort ~(tap in kel) |=([a=weft b=weft] (gth num.a num.b)))
  |=(=weft "[%{(trip lal.weft)} {(a-co:co num.weft)}]")
::
++  version-tape
  |=  =version:dock
  ^-  tape
  =,  version
  "{(a-co:co major)}.{(a-co:co minor)}.{(a-co:co patch)}"
::
++  dudes-tape
  |=  duz=(list dude:gall)
  ^-  tape
  (zing (join " " (turn duz |=(d=dude:gall "%{(trip d)}"))))
::
++  zest-tape
  |=  =zest:clay
  ^-  tape
  ?-  zest
    %live  "running"
    %dead  "suspended"
    %held  "suspended until its next update"
  ==
::
::  +make-plan: what committing an upload to a desk would do
::
++  make-plan
  |=  [[=mode =desk] from=desk =mapp]
  ^-  plan
  =/  doms  domes
  =/  syns  syncs
  =/  dom=(unit dome:clay)  (~(get by doms) desk)
  =/  exists=?  ?=(^ dom)
  =/  =zest:clay  ?~(dom %dead liv.u.dom)
  =/  rev=@ud  ?~(dom 0 let.u.dom)
  =/  lobes=(map path @uvI)  ?:(=(0 rev) ~ (desk-lobes desk))
  =/  new=(set path)  ~(key by mapp)
  =/  old=(set path)  ~(key by lobes)
  =/  gone=(set path)  (~(dif in old) new)
  =/  after=(set path)  ?:(?=(%m mode) (~(uni in old) new) new)
  =/  in-upload  ~(has by mapp)
  ::  where kiln overwrites the desk from, and the sync |pause can stop
  ::
  =/  syn  ?.(exists ~ (~(get ja syns) desk))
  =/  source=(unit [her=ship sud=^desk])
    %+  roll  syn
    |=  [[her=ship sud=^desk via=(unit ^desk) *] out=(unit [her=ship sud=^desk])]
    ?^  out  out
    ?^(via ~ `[her sud])
  ::  uploaded files the desk already has: unchanged, changed, or maybe
  ::  changed, if we can only guess how clay would convert them
  ::
  =/  [same=(set path) puts=(set path) maybe=(set path)]
    %+  roll  ~(tap in (~(int in new) old))
    |=  [pax=path same=(set path) puts=(set path) maybe=(set path)]
    =/  [exact=? lobs=(list @uvI)]  (stored-lobes pax (~(got by mapp) pax))
    ?.  =(~ (find ~[(~(got by lobes) pax)] lobs))
      [(~(put in same) pax) puts maybe]
    ?:  exact  [same (~(put in puts) pax) maybe]
    [same puts (~(put in maybe) pax)]
  =/  adds=(set path)  (~(dif in new) old)
  ::  whether the commit surely changes the desk, or maybe does
  ::
  =/  changes=?  |(!=(~ adds) !=(~ puts) &(?=(%r mode) !=(~ gone)))
  =/  unsure=?  !=(~ maybe)
  ::  the special files, as they'll be after the commit
  ::
  =/  pick
    |=  pax=path
    ^-  (unit page:clay)
    ?^  pag=(~(get by mapp) pax)  pag
    ?.  ?=(%m mode)  ~
    (bind (~(get by lobes) pax) blob)
  =/  kel=(unit (set weft))  (biff (pick /sys/kelvin) read-kelvins)
  =/  new-kel=?  (in-upload /sys/kelvin)
  =/  fate=(unit ?(%ok %old %wait %drop %now))
    ?~  kel  ~
    ?:  =(%base desk)  `(base-fate u.kel doms)
    `(kelvin-fate u.kel)
  =/  held=?  &(new-kel ?=([~ %wait] fate))
  =/  duz=(list dude:gall)  (fall (biff (pick /desk/bill) read-dudes) ~)
  ::  whether the desk's agents run after the commit without a revive
  ::
  ::    clay starts a %held desk after a commit that changes it, unless
  ::    the commit waits for a newer kernel.
  ::
  =/  live=?  |(?=(%live zest) &(?=(%held zest) changes !held))
  ::  agents of ours that other running desks run too
  ::
  =/  clash=(list [dude:gall ^desk])
    =/  runs=(list dude:gall)  (override duz ?~(dom ~ ren.u.dom))
    %-  zing
    %+  turn  ~(tap by doms)
    |=  [d=^desk =dome:clay]
    ^-  (list [dude:gall ^desk])
    ?:  |(=(d desk) !?=(%live liv.dome))  ~
    =/  theirs=(list dude:gall)
      %+  override
        (fall (biff (desk-page d /desk/bill) read-dudes) ~)
      ren.dome
    %+  murn  runs
    |=  =dude:gall
    ?~  hit=(find ~[dude] theirs)  ~
    `[dude d]
  =/  revive=(unit @t)
    ?:  live  ~
    ?:  =(%kids desk)  `'Clay never runs agents from %kids'
    ?:  held  `'Clay will hold the upload until your ship upgrades'
    ?^  clash  `'other running desks already run some of its agents'
    ?:  ?=([~ %ok] fate)  ~
    `(crip "it doesn't support this ship's kernel, [%zuse {(a-co:co zuse)}]")
  ::
  =/  nom=tape  "%{(trip desk)}"
  =/  kels=tape  ?~(kel "" (wefts-tape u.kel))
  =/  ours=tape  "[%zuse {(a-co:co zuse)}]"
  =|  errs=(list tape)
  =|  warns=(list tape)
  ::  the target
  ::
  =?  errs  =(~ mapp)  ["The upload is empty." errs]
  =?  errs  &(?=(%n mode) exists)
    ["A desk called {nom} already exists." errs]
  =?  errs  &(?=(%n mode) =(%$ desk))
    ["Give the new desk a name." errs]
  =?  errs  &(?=(%n mode) !=(%$ desk) !((sane %tas) desk))
    :_  errs
    "{nom} isn't a valid desk name. Use lowercase letters, numbers and hyphens, starting with a letter."
  =?  errs  &(!?=(%n mode) !exists)
    ["There is no desk called {nom}." errs]
  =?  errs  &(?=(%r mode) =(%base desk))
    ["deskjam won't replace %base, which holds your ship's kernel." errs]
  =?  errs  &(?=(%r mode) =(%kids desk))
    ["deskjam won't replace %kids, which your ship's moons and children take their kernel from." errs]
  ::  only files that change matter: unchanged ones aren't committed
  ::
  =/  touched=(list path)
    ~(tap in (~(uni in adds) (~(uni in puts) maybe)))
  =?  warns  &(?=(%m mode) =(%base desk))
    :_  warns
    ;:  weld
      "%base holds your ship's kernel and system apps."
      ?.  (lien touched |=(p=path =(/desk/bill p)))  ""
      " This upload changes its /desk/bill, and a wrong one stops your ship's system agents."
      ::  a held upload's kernel change is described with the kelvin
      ::
      ?:  |(held !(lien touched |=(p=path ?=([%sys *] p))))  ""
      " This upload changes files under /sys, so Clay runs a kernel update, which suspends running desks that don't support the kernel."
    ==
  =?  warns  &(?=(%m mode) =(%kids desk))
    ["%kids is what your ship's moons and children take their kernel from." warns]
  ::  the kernel it's for
  ::
  =?  errs  !(~(has in after) /sys/kelvin)
    ["The desk would have no /sys/kelvin, which every desk needs." errs]
  =?  errs  &((~(has in after) /sys/kelvin) ?=(~ kel))
    ["Can't read the /sys/kelvin the desk would have." errs]
  =?  errs  &(new-kel ?=([~ %drop] fate))
    :_  errs
    ?:  =(%base desk)
      "%base only takes its own kernel or a newer one, and the upload's /sys/kelvin ({kels}) is older, so Clay would ignore it."
    "The upload's /sys/kelvin ({kels}) lists no kernel that Clay can use, so Clay would ignore it."
  =?  warns  &(new-kel ?=([~ %now] fate))
    :_  warns
    "This upload changes your ship's kernel from {ours} to {kels} as soon as it's committed, and suspends running desks that don't support the new one."
  =?  warns  &(new-kel ?=([~ %wait] fate))
    :_  warns
    ?:  =(%base desk)
      "This upload is for a newer kernel ({kels}). Clay will hold it and upgrade your ship's kernel once every essential running desk supports {kels}. Nothing changes until then."
    ?:  ?=(%live zest)
      "This build is for a newer kernel ({kels}) than your ship runs ({ours}). Clay will hold it and apply it when your ship upgrades, and {nom} keeps running its current build until then."
    ?:  ?=(%n mode)
      "This build is for a newer kernel ({kels}) than your ship runs ({ours}). Committing it creates {nom} as an empty, suspended desk now and holds the build there, but Clay only applies held builds to desks that are running when your ship upgrades. After the upgrade, upload it again and merge it into {nom}."
    "This build is for a newer kernel ({kels}) than your ship runs ({ours}). Clay will hold it, but it only applies held builds to desks that are running when your ship upgrades, so upload it again after the upgrade. Nothing changes now."
  =/  waits=(set weft)  ?~(dom ~ (waiting u.dom (fall kel ~)))
  =?  warns  &(new-kel ?=([~ %old] fate))
    :_  warns
    =/  how=tape
      ?:  ?=(%live zest)  "{nom} keeps running with it"
      ?:  live  "Clay will still try to start {nom} with it after the commit"
      ?:  &(?=(%held zest) unsure)
        "if the upload changes anything, Clay will still try to start {nom} with it"
      ?:  ?=(%held zest)  "{nom} stays suspended"
      "Clay won't let you start {nom} with it"
    ::  what becomes of it at the next kernel update
    ::
    =/  then=tape
      ?.  |(live &(?=(%held zest) unsure))  ""
      ?.  =(~ waits)
        ". At the next kernel update, Clay replaces it with the build waiting for that kernel"
      ?:  &(exists .^(? %cx /[sour]//[snow]/esse/[desk]))
        ". {nom} is an essential desk, so your ship won't take its next kernel update until {nom} has a build for it, or you suspend {nom}"
      ", and Clay will suspend {nom} at the next kernel update"
    "This build is for an older kernel ({kels}) than your ship runs ({ours}). Clay accepts it on a best-effort basis: {how}{then}."
  ::  agents and tile
  ::
  =?  warns
      ?&  (in-upload /desk/bill)
          ?=(~ (read-dudes (~(got by mapp) /desk/bill)))
      ==
    ["Can't read the upload's /desk/bill, so Clay may reject it." warns]
  =?  errs
      &(?=(%r mode) (~(has in old) /desk/bill) !(in-upload /desk/bill))
    :_  errs
    "The upload has no /desk/bill, so replacing {nom} would stop all of its agents."
  =?  warns
      ?&  (in-upload /desk/docket-0)
          ?=(~ (read-docket (~(got by mapp) /desk/docket-0)))
      ==
    ["Can't read the upload's /desk/docket-0, so Clay may reject it." warns]
  =?  warns
      &(?=(%r mode) (~(has in old) /desk/docket-0) !(in-upload /desk/docket-0))
    :_  warns
    "The upload has no /desk/docket-0, so {nom}'s tile will disappear from Landscape."
  ::  a mark file for every kind of file
  ::
  =/  missing=(list mark)
    %+  skip
      %~  tap  in
      %-  silt
      %+  murn  ~(tap in new)
      |=  p=path
      ^-  (unit mark)
      ?~  p  ~
      =/  m=mark  (rear p)
      ::  clay converts to these without mark files
      ::
      ?:(?=(?(%hoon %noun) m) ~ `m)
    |=  m=mark
    %+  lien  (segments:clay m)
    |=(s=path (~(has in after) [%mar (snoc s %hoon)]))
  =?  errs  !=(~ missing)
    :_  errs
    =/  exts  (zing (join ", " (turn missing |=(m=mark ".{(trip m)}"))))
    "Clay would reject the upload: the desk would have no mark file for {exts} files. Add the marks to the upload."
  ::  kiln, and other running desks
  ::
  =.  warns
    %+  weld
      %+  turn  syn
      |=  [her=ship sud=^desk via=(unit ^desk) auto=?]
      ^-  tape
      =/  how=tape  (sync-tape her sud via auto)
      ?^  via
        "{nom} is overwritten from outside: {how}, which will undo this upload."
      "{nom} is overwritten from outside: {how}, so their next update will undo this upload. To keep yours, stop the sync below."
    warns
  =/  clashes=tape
    %-  zing
    %+  join  ", "
    %+  turn  clash
    |=([d=dude:gall s=^desk] "%{(trip d)} (on %{(trip s)})")
  =?  errs  &(=(%base desk) !=(~ clash))
    :_  errs
    "Other running desks already run some of these agents ({clashes}), so Clay would reject this commit to %base."
  =?  warns  &(!=(%base desk) live !=(~ clash))
    :_  warns
    "Other running desks already run some of this app's agents: {clashes}. {nom} would take them over, and every later kernel update would then fail with 'cannot run app from two desks' until one of the two desks stops listing them in its /desk/bill."
  =?  warns  &(!live !=(~ clash) !=(%kids desk) !held)
    :_  warns
    "Other running desks already run some of this app's agents: {clashes}. {nom} can't be started while they do."
  =?  warns  !=(~ waits)
    :_  warns
    =/  when=tape
      ?:  live  "When your ship upgrades"
      "If {nom} is running when your ship upgrades"
    "{nom} has an update waiting for a newer kernel ({(wefts-tape waits)}). {when}, Clay will apply that update over this one."
  ::  what the upload is
  ::
  =?  warns  &(!?=(%n mode) exists !=(from desk))
    ["This upload is a copy of %{(trip from)}, not {nom}." warns]
  =?  warns  &(?=(%m mode) !=(~ gone))
    :_  warns
    =/  k=@ud  ~(wyt in gone)
    =/  them=tape  ?:(=(1 k) "it" "them")
    "{(plural k "file")} on {nom} {?:(=(1 k) "isn't" "aren't")} in the upload, and merging leaves {them} in place. To delete {them}, replace the desk instead."
  =?  warns  &(exists !?=(%n mode) !changes !unsure)
    :_  warns
    "The upload has no changes for {nom}: Clay will make no new revision."
  =?  warns  &(?=(%held zest) !changes unsure !held)
    :_  warns
    "If any of the files that may change do, Clay will start {nom} in a separate step after this commit. If none do, Clay makes no new revision and {nom} stays suspended, unless you start it below."
  :*  mode  desk  from  exists  zest  rev
      adds  puts  same  maybe
      ?:(?=(%r mode) gone ~)
      ?:(?=(%m mode) gone ~)
      duz  source  live  held  revive
      (turn (flop errs) crip)
      (turn (flop warns) crip)
  ==
--
