/-  *deskjam
/+  multipart, dock=docket, dg=deskjam-guard
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
::    a file's last two segments are its name and mark. a file with
::    fewer, which a hand-made upload can have, sits at the root.
::
++  path-to-ancestors
  |=  [pat=path dir=?]
  ^-  (list path)
  =.  pat  (flop pat)
  =?  pat  !dir  ?:(?=([@ @ *] pat) t.t.pat ~)
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
::  +files-to-hierarchy: rows listing files under the folders they sit
::  in, in order
::
::    sorts the files once, and adds only the folders a file doesn't
::    share with the file before it, so it takes time linear in the
::    rows it makes. a file's last two segments are its name and mark;
::    one with fewer, which a hand-made upload can have, sits at the root.
::
++  files-to-hierarchy
  |=  pax=(list path)
  ^-  (list [pat=path dir=? dep=@])
  =/  fis=(list path)  (sort pax aor)
  =/  out=(list [pat=path dir=? dep=@])  ~[[/ & 0]]
  =/  pre=path  /
  |-  ^+  out
  ?~  fis  (flop out)
  =/  dir=path  (folder i.fis)
  =/  len=@ud  (lent dir)
  =.  out
    =/  k=@ud  (shared pre dir)
    |-  ^+  out
    ?:  (gte k len)  out
    $(k +(k), out [[(scag +(k) dir) & +(k)] out])
  $(fis t.fis, pre dir, out [[i.fis | +(len)] out])
::
::  +folder: the folder a file sits in
::
++  folder
  |=  pat=path
  ^-  path
  =/  len=@ud  (lent pat)
  ?:  (lth len 2)  ~
  (scag (sub len 2) pat)
::
::  +shared: how many leading segments two paths have in common
::
++  shared
  |=  [a=path b=path]
  ^-  @ud
  =|  n=@ud
  |-  ^-  @ud
  ?~  a  n
  ?~  b  n
  ?.  =(i.a i.b)  n
  $(a t.a, b t.b, n +(n))
::
::  +display-paths: the paths a page lists of an upload's, and how many
::  more it has
::
::    a crafted upload can have more files, or deeper paths, than a
::    page can list in reasonable time
::
::    a page lists files in order until their rows, with the folders
::    they add, would pass 2,500, and shows a path at most 20 segments
::    deep
::
++  display-paths
  |=  pax=(list path)
  ^-  [(list path) @ud]
  =/  fis=(list path)  (sort pax aor)
  =|  out=(list path)
  =/  pre=path  /
  =/  rows=@ud  1
  |-  ^-  [(list path) @ud]
  ?~  fis  [(flop out) 0]
  =/  pat=path
    =/  len=@ud  (lent i.fis)
    ?:  (lte len 20)  i.fis
    (weld (scag 17 i.fis) `path`['...' (slag (sub len 2) i.fis)])
  =/  dir=path  (folder pat)
  =/  new=@ud  +((sub (lent dir) (shared pre dir)))
  ?:  (gth (add rows new) 2.500)  [(flop out) (lent fis)]
  $(fis t.fis, out [pat out], pre dir, rows (add rows new))
::
::  desk state
::
::  +desk-exists: whether clay knows a desk, with or without commits
::
++  desk-exists  |=(=desk (~(has in desks) desk))
::
::  +has-files: whether a desk exists and has a commit, so has files
::
++  has-files
  |=  =desk
  ^-  ?
  !=(0 (desk-rev desk))
::
::  +desk-rev: a desk's revision, 0 if it has none
::
++  desk-rev
  |=  =desk
  ^-  @ud
  ?~(dom=(~(get by domes) desk) 0 let.u.dom)
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
::  +unpack: the desk a .deskjam file holds, or why it holds none
::
::    a crafted file can unpack to a noun whose tree is exponentially
::    larger than the file, and checking its shape then takes that
::    long, hanging the ship. a real deskjam unpacks to far fewer cells
::    than the file has bits, so refuse anything with more, or with more
::    than +budget:dg allows a big file.
::
++  unpack
  |=  jam=@
  ^-  (each deskpack ?(%not %bomb))
  ?~  non=(mole |.((cue jam)))  |+%not
  ?.  (bounded:dg (budget:dg (met 0 jam)) u.non)  |+%bomb
  ?.  ?=([%deskpack-0 *] u.non)  |+%not
  ?~  pack=(mole |.(;;(deskpack +.u.non)))  |+%not
  &+u.pack
::
::  reading special files
::
::    jammer and |commit produce %mime pages; deskjam's own downloads
::    hold pages of each file's own mark. read both kinds.
::
::    clay reads /desk/bill, /desk/docket-0 and /sys/kelvin by parsing
::    and evaluating them as hoon. an upload's are read before anything
::    is confirmed, and crafted ones could take forever to parse or to
::    evaluate, so read them with +read:dg, which only takes literals.
::
++  page-text
  |=  =page:clay
  ^-  (unit @t)
  ?.  ?=(%mime p.page)  ~
  (bind (mole |.(;;(mime q.page))) |=(=mime `@t`q.q.mime))
::
::  +text-to-waft: +cord-to-waft:clay, for kelvins written as literals
::
++  text-to-waft
  |=  =cord
  ^-  waft:clay
  =/  wefts=(list weft)
    (turn (need (read:dg cord)) |=(non=* ;;(weft non)))
  ?:  ?=([* ~] wefts)
    i.wefts
  [[%1 ~] (sy wefts)]
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
    %mime    (text-to-waft q.q:;;(mime q.page))
  ==
::
++  read-dudes
  |=  =page:clay
  ^-  (unit (list dude:gall))
  %-  mole  |.
  ?^  tex=(page-text page)
    ;;((list dude:gall) (need (read-one:dg u.tex)))
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
      ;;((list clause:dock) (need (read-one:dg u.tex)))
    `;;(docket:dock q.page)
  same
::
::  the app's glob: its web frontend, which landscape's %docket agent
::  fetches as the desk's docket says
::
::  +glob-ref: where a docket says its glob comes from, if it has one
::
++  glob-ref
  |=  doc=(unit docket:dock)
  ^-  (unit glob-reference:dock)
  ?~  doc  ~
  ?.  ?=(%glob -.href.u.doc)  ~
  `glob-reference.href.u.doc
::
::  +served-here: whether a glob reference has our ship serve the glob
::
++  served-here
  |=  ref=(unit glob-reference:dock)
  ^-  ?
  ?~  ref  |
  &(?=(%ames -.location.u.ref) =(our ship.location.u.ref))
::
::  +glob-tape: where a glob comes from
::
++  glob-tape
  |=  ref=glob-reference:dock
  ^-  tape
  =/  hash=tape  (scow %uv hash.ref)
  ?-  -.location.ref
    %http  "from {(trip url.location.ref)}, hash {hash}"
    %ames  ?:  =(our ship.location.ref)
             "from this ship, hash {hash}"
           "from {(scow %p ship.location.ref)}, hash {hash}"
  ==
::
::  +upload-docket: the docket a desk would have after a commit
::
++  upload-docket
  |=  [[=mode =desk] =mapp]
  ^-  (unit docket:dock)
  ?^  pag=(~(get by mapp) /desk/docket-0)  (read-docket u.pag)
  ?.  ?=(%m mode)  ~
  (biff (desk-page desk /desk/docket-0) read-docket)
::
::  +serve-glob: .mapp with its docket set to have our ship serve the
::  app's glob with .hash, as /docket/upload sets it when it takes one
::
::    ~ if the docket the desk would have has no glob
::
++  serve-glob
  |=  [[=mode =desk] =mapp hash=@uvH]
  ^-  (unit ^mapp)
  ?~  doc=(upload-docket [mode desk] mapp)  ~
  ?.  ?=(%glob -.href.u.doc)  ~
  =.  glob-reference.href.u.doc  [hash %ames our]
  `(~(put by mapp) /desk/docket-0 [%docket-0 u.doc])
::
::  +with-glob: .mapp as the commit would write it: with its glob served
::  from our ship, if the user chose a hash for that
::
++  with-glob
  |=  [[=mode =desk] =mapp hash=(unit @uvH)]
  ^-  ^mapp
  ?~  hash  mapp
  (fall (serve-glob [mode desk] mapp u.hash) mapp)
::
::  dependencies
::
::    clay builds a file's mark whenever it commits the file. when a desk
::    with agents runs, it builds every mark on it, and every agent its
::    bill lists, each with the files it imports. if one is missing,
::    clay refuses the commit, so look for them first, reading ford
::    headers as clay does.
::
+$  want
  $%  [%hoon =path]                                     ::  a hoon file
      [%file =path]                                     ::  any file
      [%mark mak=@t]                                    ::  a mark
  ==
::
::  +lacks: what building .roots needs that a desk with files .after
::  would lack, each with what needs it
::
::    .text reads a file the desk would have. a header deskjam can't
::    read, such as one with /~, isn't followed.
::
++  lacks
  |=  [after=(set path) text=$-(path (unit @t)) roots=(list want)]
  ^-  (list tape)
  =/  sur  (by-name after %sur)
  =/  lib  (by-name after %lib)
  =/  mar  (by-name after %mar)
  =/  todo=(list [want tape])  (turn roots |=(n=want [n ""]))
  =|  seen=(set want)
  =|  out=(list tape)
  |-  ^-  (list tape)
  ?~  todo  (flop out)
  =/  [nod=want who=tape]  i.todo
  ?:  (~(has in seen) nod)  $(todo t.todo)
  =.  seen  (~(put in seen) nod)
  =/  gone
    |=  what=tape
    ^-  tape
    ?~  who  what
    "{what}, which {who} needs"
  ?-    -.nod
      %file
    ?:  (~(has in after) path.nod)  $(todo t.todo)
    $(todo t.todo, out [(gone (spud path.nod)) out])
  ::
      %mark
    ?~  fil=(~(get by mar) mak.nod)
      $(todo t.todo, out [(gone "a mark file for %{(trip mak.nod)}") out])
    =/  grad=(unit (unit @t))  (biff (text u.fil) read-grad:dg)
    =/  more=(list [want tape])
      :-  [[%hoon u.fil] who]
      ?.  ?=([~ ~ @] grad)  ~
      [[%mark u.u.grad] (spud u.fil)]~
    $(todo (weld more t.todo))
  ::
      %hoon
    ?.  (~(has in after) path.nod)
      $(todo t.todo, out [(gone (spud path.nod)) out])
    ?~  tex=(text path.nod)  $(todo t.todo)
    ?~  imp=(read-imports:dg u.tex)  $(todo t.todo)
    =/  from=tape  (spud path.nod)
    =/  find-in
      |=  [top=@ta names=(map @t path)]
      |=  nam=@t
      ^-  [want tape]
      :_  from
      [%hoon (fall (~(get by names) nam) /[top]/[nam]/hoon)]
    =/  more=(list [want tape])
      %-  zing
      ^-  (list (list [want tape]))
      :~  (turn sur.u.imp (find-in %sur sur))
          (turn lib.u.imp (find-in %lib lib))
          (turn raw.u.imp |=(p=path `[want tape]`[[%hoon (snoc p %hoon)] from]))
          (turn maz.u.imp |=(m=@t `[want tape]`[[%mark m] from]))
        ::
          %-  zing
          %+  turn  caz.u.imp
          |=  [a=@t b=@t]
          ^-  (list [want tape])
          ?:  |(=(a b) &(=('mime' a) =('hoon' b)))  ~
          ~[[[%mark a] from] [[%mark b] from]]
        ::
          %-  zing
          %+  turn  bar.u.imp
          |=  [m=@t p=path]
          ^-  (list [want tape])
          ~[[[%file p] from] [[%mark m] from]]
      ==
    $(todo (weld more t.todo))
  ==
::
::  +by-name: the hoon files under /.top, by the name ford finds each by:
::  its path below .top, joined with hyphens
::
++  by-name
  |=  [after=(set path) top=@ta]
  ^-  (map @t path)
  %-  ~(gas by *(map @t path))
  %+  murn  ~(tap in after)
  |=  p=path
  ^-  (unit [@t path])
  ?.  &(?=([@ @ *] p) =(top i.p))  ~
  ?.  =(%hoon (rear `path`p))  ~
  =/  mid=path  (snip `path`t.p)
  ?~  mid  ~
  `[(crip (zing (join "-" (turn `(list @ta)`mid trip)))) p]
::
::  +file-text: the text of a hoon file's page, as an upload or clay holds it
::
++  file-text
  |=  =page:clay
  ^-  (unit @t)
  ?:  ?=(%hoon p.page)  (mole |.(;;(@t q.page)))
  (page-text page)
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
      %kelvin    (bind (mole |.((text-to-waft q.oct))) one)
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
++  older
  |=  [a=version:dock b=version:dock]
  ^-  ?
  ?.  =(major.a major.b)  (lth major.a major.b)
  ?.  =(minor.a minor.b)  (lth minor.a minor.b)
  (lth patch.a patch.b)
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
  ::  the agents clay would run from the desk, after its rein
  ::
  =/  runs=(list dude:gall)  (override duz ?~(dom ~ ren.u.dom))
  ::  agents of ours that other running desks run too
  ::
  ::    since 408k-2, a commit or start only builds its own desk's agents,
  ::    so gall moves a clashing agent over, state and all. clay only
  ::    notices the clash when it builds every desk's agents, as at any
  ::    commit to %base, which then crashes. 408k crashed the commit.
  ::
  =/  clash=(list [dude:gall ^desk])
    %-  zing
    %+  turn  ~(tap by doms)
    |=  [d=^desk =dome:clay]
    ^-  (list [dude:gall ^desk])
    ?:  |(=(d desk) !?=(%live liv.dome))  ~
    =/  theirs=(list dude:gall)
      %+  override
        (fall (biff (desk-page d /desk/bill) read-dudes) ~)
      ren.dome
    %+  murn  ~(tap in (silt runs))
    |=  =dude:gall
    ?~  hit=(find ~[dude] theirs)  ~
    `[dude d]
  ::  agents the desk would list without a file to build them from
  ::
  =/  bare=(list dude:gall)
    (skip runs |=(d=dude:gall (~(has in after) /app/[d]/hoon)))
  ::  agents the bill lists twice, which clay refuses to run, as it
  ::  would an agent two desks list
  ::
  =/  twice=(list dude:gall)
    =|  [seen=(set dude:gall) out=(list dude:gall)]
    =/  all=(list dude:gall)  runs
    |-  ^-  (list dude:gall)
    ?~  all  (flop out)
    =?  out  &((~(has in seen) i.all) ?=(~ (find ~[i.all] out)))
      [i.all out]
    $(all t.all, seen (~(put in seen) i.all))
  ::  the text of a file the desk would have
  ::
  =/  text
    |=  pax=path
    ^-  (unit @t)
    ?^  pag=(~(get by mapp) pax)  (file-text u.pag)
    ?.  ?=(%m mode)  ~
    ?~  lob=(~(get by lobes) pax)  ~
    (file-text (blob u.lob))
  ::  files the desk would lack to run: running a desk with agents
  ::  builds them, and every mark on it
  ::
  =/  short=(list tape)
    ?~  runs  ~
    %^  lacks  after  text
    %+  weld
      %+  turn
        (skip `(list dude:gall)`runs |=(d=dude:gall ?=(^ (find ~[d] bare))))
      |=(d=dude:gall `want`[%hoon /app/[d]/hoon])
    (turn ~(tap in ~(key by (by-name after %mar))) |=(m=@t `want`[%mark m]))
  ::  whether the desk's agents run after the commit without a revive
  ::
  ::    clay starts a %held desk after a commit that changes it, unless
  ::    the commit waits for a newer kernel, but the start fails if an
  ::    agent can't be built.
  ::
  =/  live=?
    ?|  ?=(%live zest)
        &(?=(%held zest) changes !held =(~ bare) =(~ short) =(~ twice))
    ==
  =/  revive=(unit @t)
    ?:  live  ~
    ?:  =(%kids desk)  `'Clay never runs agents from %kids'
    ?:  held  `'Clay will hold the upload until your ship upgrades'
    ?^  bare  `'its /desk/bill lists agents it has no /app file for'
    ?^  twice  `'its /desk/bill lists an agent twice'
    ?^  short  `'it would lack files its agents or marks need'
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
  =?  errs  (~(has by mapp) /)
    ["The upload has a file with an empty path, which Clay can't store." errs]
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
    :_  errs
    "Can't read the /sys/kelvin the desk would have. deskjam only reads one that writes its kernels out, as [%zuse 408]."
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
  ::  agents the desk runs now that its new bill drops
  ::
  =/  dropped=(list dude:gall)
    ?.  &(?=(%live zest) !held ?=(^ dom))  ~
    %+  skip
      %+  override
        (fall (biff (bind (~(get by lobes) /desk/bill) blob) read-dudes) ~)
      ren.u.dom
    |=(d=dude:gall ?=(^ (find ~[d] runs)))
  =?  warns  !=(~ dropped)
    :_  warns
    "This upload's /desk/bill no longer lists {(dudes-tape dropped)}, which {nom} runs now. Gall will stop them and keep their state."
  ::  the app's glob, which landscape's %docket agent serves
  ::
  ::    %docket only fetches a glob from elsewhere. one that the docket
  ::    says our ship serves, it waits for someone to upload at
  ::    /docket/upload, unless it already has a glob with that hash.
  ::
  =/  doc-old=(unit docket:dock)
    ?~  lob=(~(get by lobes) /desk/docket-0)  ~
    (read-docket (blob u.lob))
  =/  doc-new=(unit docket:dock)  (biff (pick /desk/docket-0) read-docket)
  =/  ref-old=(unit glob-reference:dock)  (glob-ref doc-old)
  =/  ref-new=(unit glob-reference:dock)  (glob-ref doc-new)
  =?  warns
      ?&  ?=(^ ref-new)
          ?=(%http -.location.u.ref-new)
          ?=(~ (de-purl:html url.location.u.ref-new))
      ==
    :_  warns
    "%docket couldn't fetch {nom}'s glob: the url in its docket isn't one it can read."
  ::  other ships ask our %docket for a glob by their desk's name, which
  ::  it looks up among its dockets' bases
  ::
  =?  warns
      ?&  (served-here ref-new)
          ?=(^ doc-new)
          ?=(%glob -.href.u.doc-new)
          !=(desk base.href.u.doc-new)
      ==
    :_  warns
    "{nom}'s docket has the base %{(trip base.href.u.doc-new)}. Other ships ask your ship for the glob by the name of their desk, so it has to be the same as the base: name the desk %{(trip base.href.u.doc-new)}, or change the base."
  =?  warns
      ?&  ?=(^ doc-new)
          ?=(^ doc-old)
          (older version.u.doc-new version.u.doc-old)
      ==
    :_  warns
    "The upload is version {(version-tape version.u.doc-new)}, older than the {(version-tape version.u.doc-old)} {nom} has now."
  =?  warns  &((served-here ref-new) !=(ref-old ref-new))
    :_  warns
    ?>  ?=(^ ref-new)
    =/  new=tape  (scow %uv hash.u.ref-new)
    ?.  (served-here ref-old)
      "{nom}'s docket would have your ship serve its glob, the app's web frontend, with hash {new}. Unless your ship already has that glob, {nom} has no frontend until you upload it at /docket/upload."
    ?>  ?=(^ ref-old)
    =/  old=tape  (scow %uv hash.u.ref-old)
    "{nom}'s docket would change its glob's hash from {old} to {new}. Your ship serves {nom}'s glob itself, so {nom} has no frontend until you upload the glob with hash {new} at /docket/upload. To keep serving the glob it has, serve the glob with hash {old} below."
  =?  warns  &((served-here ref-old) ?=(^ ref-new) !(served-here ref-new))
    :_  warns
    ?>  ?=(^ ref-new)
    "{nom}'s docket would have its glob fetched {(glob-tape u.ref-new)}, instead of served by your ship."
  ::  when a suspended desk starts again, %docket forgets the glob it
  ::  served, hash or no hash, and waits for an upload
  ::
  =?  warns
      ?&  exists
          !?=(%live zest)
          (served-here ref-new)
          =(ref-old ref-new)
          |(live =(~ revive))
      ==
    :_  warns
    "{nom} isn't running. When it starts, Landscape's %docket forgets the glob your ship served for it, even with the same hash, so upload the glob again at /docket/upload afterwards."
  ::  a mark file for every kind of file
  ::
  ::    clay finds mark %a-b at /mar/a/b/hoon or /mar/a-b/hoon. trying
  ::    each way to split a mark at its hyphens takes time exponential
  ::    in them, so instead join the desk's mark paths with hyphens.
  ::
  =/  marks=(set @t)
    %-  silt
    %+  murn  ~(tap in after)
    |=  p=path
    ^-  (unit @t)
    ?.  ?=([%mar @ *] p)  ~
    ?.  =(%hoon (rear `path`p))  ~
    =/  mid=path  (snip `path`t.p)
    ?~  mid  ~
    `(crip (zing (join "-" (turn `(list @ta)`mid trip))))
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
    ~(has in marks)
  =?  errs  !=(~ missing)
    :_  errs
    =/  exts  (zing (join ", " (turn missing |=(m=mark ".{(trip m)}"))))
    "Clay would reject the upload: the desk would have no mark file for {exts} files. Add the marks to the upload."
  ::  what the marks and agents clay builds need
  ::
  ::    clay builds the mark of each file it commits, whether or not the
  ::    desk runs, with whatever the mark imports or hands its diffs to
  ::
  =/  listed
    |=  items=(list tape)
    ^-  tape
    =/  n=@ud  (lent items)
    =/  some=tape  (zing (join "; " (scag 8 items)))
    =/  rest=tape  ?:((lte n 8) "" "; and {(a-co:co (sub n 8))} more")
    (weld some rest)
  =/  unbuilt=(list tape)
    %^  lacks  after  text
    %+  turn
      %~  tap  in
      %-  silt
      %+  murn  ~(tap in (~(uni in adds) (~(uni in puts) maybe)))
      |=  p=path
      ^-  (unit @t)
      ?~  p  ~
      =/  m=@t  (rear p)
      ?:  |(=('hoon' m) =('noun' m) ?=(^ (find ~[m] `(list @t)`missing)))
        ~
      `m
    |=(m=@t `want`[%mark m])
  =?  errs  !=(~ unbuilt)
    :_  errs
    "Clay would reject the upload: it builds the mark of each file it commits, and those marks need files the desk would lack: {(listed unbuilt)}."
  =/  run-short=(list tape)  (skip short |=(t=tape ?=(^ (find ~[t] unbuilt))))
  =?  errs  &(!=(~ run-short) ?=(%live zest) !held)
    :_  errs
    "Clay would reject this commit: {nom} runs, so Clay builds its agents and all its marks in the commit, and they need files it would lack: {(listed run-short)}."
  =?  warns  &(!=(~ run-short) |(!?=(%live zest) held) !=(%kids desk))
    :_  warns
    "{nom}'s agents and marks need files it would lack, so Clay couldn't run it: {(listed run-short)}."
  =?  errs  &(!=(~ twice) ?=(%live zest) !held)
    :_  errs
    "{nom}'s /desk/bill would list {(dudes-tape twice)} more than once, so Clay would reject this commit: it won't run an agent twice."
  =?  warns  &(!=(~ twice) |(!?=(%live zest) held) !=(%kids desk))
    :_  warns
    "{nom}'s /desk/bill would list {(dudes-tape twice)} more than once, so Clay couldn't run {nom}."
  ::  json files that don't parse: the standard json mark stores each as
  ::  null, without a word
  ::
  =/  bad-json=(list path)
    %+  murn  ~(tap by mapp)
    |=  [p=path pag=page:clay]
    ^-  (unit path)
    ?.  &(?=(^ p) =(%json (rear `path`p)) ?=(%mime p.pag))  ~
    ?~  tex=(page-text pag)  ~
    ?:  (gth (met 3 u.tex) 1.048.576)  ~
    ?^  (de:json:html u.tex)  ~
    `p
  =?  warns  !=(~ bad-json)
    :_  warns
    "These files aren't valid JSON, so the standard json mark would store each as null: {(listed (turn bad-json spud))}."
  ::  other hoon files, which clay builds only when something uses them
  ::
  =/  loose=(list tape)
    %+  skip
      %^  lacks  after  text
      %+  murn  ~(tap in after)
      |=  p=path
      ^-  (unit want)
      ?.  &(?=([@ *] p) ?=(?(%lib %sur %ted %gen) i.p))  ~
      ?.  =(%hoon (rear `path`p))  ~
      `[%hoon p]
    |=(t=tape |(?=(^ (find ~[t] unbuilt)) ?=(^ (find ~[t] short))))
  =?  warns  !=(~ loose)
    :_  warns
    "Some files import files the desk would lack, so they won't build if anything uses them: {(listed loose)}."
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
  =?  warns  &(!=(%base desk) live !held !=(~ clash))
    :_  warns
    "Other running desks already run some of this app's agents: {clashes}. {nom} would take them over, state and all, and every later commit to %base, including your sponsor's updates, would then fail with 'cannot run app from two desks' until one of the two desks stops listing them in its /desk/bill. (Kernels before 408k-2 reject this commit instead.)"
  =?  warns  &(!=(%base desk) ?=(%live zest) held !=(~ clash))
    :_  warns
    "Other running desks already run some of this app's agents: {clashes}. Clay holds this upload until your ship upgrades, and the upgrade would then fail with 'cannot run app from two desks', unless one of the desks stops listing them in its /desk/bill first."
  =?  warns  &(!live !=(~ clash) !=(%kids desk) !held)
    :_  warns
    "Other running desks already run some of this app's agents: {clashes}. {nom} can't be started while they do."
  ::  agents listed without their file
  ::
  =/  bares=tape  (dudes-tape bare)
  =?  errs  &(?=(%live zest) !held !=(~ bare))
    :_  errs
    "{nom}'s /desk/bill would list {bares}, but the desk would have no /app file for them, so Clay would reject this commit."
  =?  warns  &(|(!?=(%live zest) held) !=(~ bare) !=(%kids desk))
    :_  warns
    "{nom}'s /desk/bill would list {bares}, but the desk would have no /app file for them, so Clay couldn't run {nom} with this upload."
  ::  agents of suspended desks with the same names: gall keeps their
  ::  state, and hands it to whichever desk next runs an agent so named
  ::
  =/  idle=(list [dude:gall ^desk])
    ?.  |(live =(~ revive))  ~
    %-  zing
    %+  turn  ~(tap by doms)
    |=  [d=^desk =dome:clay]
    ^-  (list [dude:gall ^desk])
    ?:  |(=(d desk) ?=(%live liv.dome))  ~
    %+  murn  ~(tap in (agents d))
    |=  [=dude:gall run=?]
    ?~  (find ~[dude] runs)  ~
    `[dude d]
  =?  warns  !=(~ idle)
    :_  warns
    =/  them=tape
      %-  zing
      %+  join  ", "
      %+  turn  idle
      |=([d=dude:gall s=^desk] "%{(trip d)} (on %{(trip s)})")
    "Suspended desks hold the saved state of agents named like this app's: {them}. When {nom} runs them, Gall gives them that state, and those desks can't be started while {nom} runs them."
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
