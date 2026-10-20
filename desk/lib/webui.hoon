/-  *deskjam
/+  rudder, multipart, w=webui-pages, h=deskjam
|%
++  path-to-term
  |=  =path
  ^-  term
  (crip (zing (join "-" (turn path trip))))
::
++  make-page
  |=  paz=path
  ^-  (pair @ta (page:rudder data action))
  :-  (path-to-term paz)
  ^-  (page:rudder data action)
  ~|  paz
  ?+    paz  !!
    [%index ~]    index
    [%staged ~]   staged
    [%confirm ~]  confirm
    [%glob ~]     glob
    [%subset ~]   subset
    [%status ~]   status
  ==
::
::  +trust: a page's message, unless a link could have forged it
::
::    rudder shows any GET's ?rmsg= as a success message, so a link
::    from anywhere could show its own text as if deskjam said it, on
::    the pages that install code. deskjam only ever sends this one.
::
++  trust
  |=  msg=(unit [o=? =@t])
  ^+  msg
  ?.  &(?=(^ msg) o.u.msg)  msg
  ?:(=('Upload staged.' t.u.msg) msg ~)
::
::  +file-part: the file a one-part multipart upload holds
::
::    +de-request:multipart parses the whole body as a list of bytes,
::    two list cells per byte, which can run the ship out of memory
::    for a desk of a few tens of MB. deskjam's form sends the file as
::    its only part, so find it with atom operations instead. ~ if the
::    body isn't that.
::
++  file-part
  |=  [headers=header-list:http body=(unit octs)]
  ^-  (unit @)
  ?~  body  ~
  ?~  cot=(get-header:http 'content-type' headers)  ~
  ?.  =('multipart/form-data; boundary=' (end 3^30 u.cot))  ~
  =/  dim=@t  (cat 3 '--' (rsh 3^30 u.cot))
  =*  len  p.u.body
  =*  dat  q.u.body
  ::  the part's headers end at its first blank line
  ::
  =/  top=tape  (trip (end [3 4.096] dat))
  ?.  =((trip (cat 3 dim '\0d\0a')) (scag (add 2 (met 3 dim)) top))  ~
  ?~  sep=(find "\0d\0a\0d\0a" top)  ~
  ?~  (find "Content-Disposition: form-data; name=\"file\"" (scag u.sep top))
    ~
  =/  start=@ud  (add 4 u.sep)
  =/  tail=@t  (rap 3 '\0d\0a' dim '--\0d\0a' ~)
  =/  tal=@ud  (met 3 tail)
  ?:  (lth len (add start tal))  ~
  ?.  =(tail (cut 3 [(sub len tal) tal] dat))  ~
  `(cut 3 [start (sub (sub len tal) start)] dat)
::
::  +stage: stage an uploaded file, or say why it can't be
::
++  stage
  |=  got=(each deskpack ?(%not %bomb))
  ^-  $@(brief:rudder action)
  ?-  -.got
    %&  [%stage-mapp p.got]
    %|  ?-  p.got
          %not   'That file isn\'t a deskjam.'
          %bomb  'That file unpacks to far more than its size, as only a crafted file would, so deskjam won\'t read it.'
        ==
  ==
::
++  index
  |_  [=bowl:gall * =data]
  +*  hc  ~(. h [our now]:bowl)
  ++  argue
    |=  [headers=header-list:http body=(unit octs)]
    ^-  $@(brief:rudder action)
    ?^  fil=(file-part headers body)
      (stage (unpack:hc u.fil))
    =/  parts  (de-request:multipart headers body)
    ?~  parts
      =/  args=(map @t @t)
        ?~(body ~ (frisk:rudder q.u.body))
      ?~  url=(~(get by args) 'url')  'Give a url to fetch.'
      [%fetch u.url (~(has by args) 'local')]
    =/  jam=(unit @)
      %-  lint:hc
      ^-  (list @)
      %+  murn  u.parts
      |=  [n=@t p=part:multipart]
      ^-  (unit @)
      ?.(=('file' n) ~ `body.p)
    ?~  jam  'Choose a file to upload.'
    (stage (unpack:hc u.jam))
  ::
  ++  final
    %+  alert:rudder
      (spat /apps/[dap.bowl]/staged)
    build
  ::
  ++  build
    |=  $:  arg=(list [k=@t v=@t])
            msg=(unit [o=? =@t])
        ==
    ^-  reply:rudder
    [%page ~(page index:w [bowl data (trust msg)])]
  --
::
++  staged
  |_  [=bowl:gall * =data]
  +*  hc  ~(. h [our now]:bowl)
  ++  argue
    |=  [headers=header-list:http body=(unit octs)]
    ^-  $@(brief:rudder action)
    =/  args=(map @t @t)
      ?~(body ~ (frisk:rudder q.u.body))
    =/  choice=(unit [=mode dex=@t])
      ::  the fields of deskjam's older form
      ::
      ?^  old=(~(get by args) 'old-desk')  `[%m u.old]
      ?^  new=(~(get by args) 'new-desk')  `[%n u.new]
      =/  how=(unit mode)
        ?+  (~(get by args) 'mode')  ~
          [~ %n]  `%n
          [~ %r]  `%r
          [~ %m]  `%m
        ==
      ?~  how  ~
      `[u.how (fall (~(get by args) 'desk') '')]
    ?~  choice  'Choose what to do with the upload.'
    ?~  staged.data  'Nothing is staged. Upload a deskjam first.'
    =,  u.choice
    ?:  ?=(%n mode)
      ?:  =('' dex)  'Give the new desk a name.'
      ?.  ((sane %tas) dex)
        %-  crip
        "%{(trip dex)} isn't a valid desk name. Use lowercase letters, numbers and hyphens, starting with a letter."
      ?:  (desk-exists:hc dex)
        (crip "A desk called %{(trip dex)} already exists.")
      [%set-dest mode dex]
    ?:  =('' dex)  'Choose a desk.'
    ?.  (desk-exists:hc dex)
      (crip "There is no desk called %{(trip dex)}.")
    [%set-dest mode dex]
  ::
  ++  final
    %+  alert:rudder
      (spat /apps/[dap.bowl]/confirm)
    build
  ::
  ++  build
    |=  $:  arg=(list [k=@t v=@t])
            msg=(unit [o=? =@t])
        ==
    ^-  reply:rudder
    [%page ~(page staged:w [bowl data (trust msg)])]
  --
::
++  confirm
  |_  [=bowl:gall * =data]
  +*  hc  ~(. h [our now]:bowl)
  ++  argue
    |=  [headers=header-list:http body=(unit octs)]
    ^-  $@(brief:rudder action)
    =/  args=(map @t @t)
      ?~(body ~ (frisk:rudder q.u.body))
    ::  the buttons of deskjam's older form
    ::
    ?:  (~(has by args) 'add-files')  [%add-files ~]
    ?:  (~(has by args) 'new-desk')  [%new-desk ~]
    ?.  (~(has by args) 'commit')  ~
    ::  if the form says what it showed, refuse to commit anything
    ::  else. compare only what it says, as a page shown by an older
    ::  deskjam says less.
    ::
    =/  shown=(list (unit @t))
      (turn ~['mode' 'desk' 'upload' 'rev' 'glob'] ~(get by args))
    =/  now=(list (unit @t))
      :~  (bind dest.data |=([=mode =desk] `@t`mode))
          (bind dest.data |=([=mode =desk] `@t`desk))
          (bind staged.data |=([=time *] (scot %da time)))
          (bind dest.data |=([=mode =desk] (crip (a-co:co (desk-rev:hc desk)))))
          `?~(glob.data '' (scot %uv u.glob.data))
      ==
    =/  changed=?
      |-  ^-  ?
      ?~  shown  |
      ?~  now  |
      ?:  &(?=(^ i.shown) !=(i.shown i.now))  &
      $(shown t.shown, now t.now)
    ::  (with nothing staged, the commit says what happened instead)
    ::
    ?:  &(?=(^ staged.data) changed)
      'The upload or its destination changed after this page was shown. Check them again, then confirm.'
    [%commit (~(has by args) 'revive') (~(has by args) 'pause')]
  ::
  ::  after a commit, show the desk it went to
  ::
  ++  final
    |=  [done=? =brief:rudder]
    ^-  reply:rudder
    =/  status=@t
      =/  dex=@t  ?~(sent.data %$ desk.u.sent.data)
      (rap 3 (spat /apps/[dap.bowl]/status) '?desk=' dex ~)
    ::  a second click on confirm finds the upload committed: show what
    ::  became of it, as the first click did
    ::
    ?:  &(!done ?=(~ staged.data) ?=(^ sent.data))
      [%next status ~]
    ?.  done  (build ~ `[| `@t`brief])
    [%next status brief]
  ::
  ++  build
    |=  $:  arg=(list [k=@t v=@t])
            msg=(unit [o=? =@t])
        ==
    ^-  reply:rudder
    [%page ~(page confirm:w [bowl data (trust msg)])]
  --
::
::  +glob: the confirm page's form for serving the app's glob from
::  our ship
::
++  glob
  |_  [=bowl:gall * =data]
  ++  argue
    |=  [headers=header-list:http body=(unit octs)]
    ^-  $@(brief:rudder action)
    =/  args=(map @t @t)
      ?~(body ~ (frisk:rudder q.u.body))
    ?:  (~(has by args) 'clear')  [%set-glob ~]
    =/  txt=tape
      %+  skip  (trip (fall (~(get by args) 'hash') ''))
      |=(c=@t |(=(' ' c) =('\09' c) =('\0a' c) =('\0d' c)))
    ?~  hash=(slaw %uv (crip txt))
      'Give the glob\'s hash as a docket writes it, starting with 0v.'
    [%set-glob hash]
  ::
  ++  final
    |=  [done=? =brief:rudder]
    ^-  reply:rudder
    ?:  done  [%next (spat /apps/[dap.bowl]/confirm) ~]
    (build ~ `[| `@t`brief])
  ::
  ::  the form is on the confirm page, which shows its errors too
  ::
  ++  build
    |=  $:  arg=(list [k=@t v=@t])
            msg=(unit [o=? =@t])
        ==
    ^-  reply:rudder
    =.  msg  (trust msg)
    ?~  msg  [%next (spat /apps/[dap.bowl]/confirm) ~]
    [%page ~(page confirm:w [bowl data msg])]
  --
::
++  status
  |_  [=bowl:gall * =data]
  ++  argue
    |=  [headers=header-list:http body=(unit octs)]
    ^-  $@(brief:rudder action)
    ~
  ::
  ++  final  (alert:rudder (spat /apps/[dap.bowl]) build)
  ::
  ++  build
    |=  $:  arg=(list [k=@t v=@t])
            msg=(unit [o=? =@t])
        ==
    ^-  reply:rudder
    =.  msg  (trust msg)
    =/  raw=(unit @t)
      =/  got  (~(get by (malt arg)) 'desk')
      ?:(=([~ ''] got) ~ got)
    =/  dex=(unit desk)  (biff raw (sand %tas))
    =?  msg  &(?=(^ raw) ?=(~ dex))
      `[| 'That isn\'t a valid desk name.']
    [%page ~(page status:w [bowl data dex msg])]
  --
::
++  subset
  |_  [=bowl:gall * =data]
  +*  hc  ~(. h [our now]:bowl)
  ++  argue
    |=  [headers=header-list:http body=(unit octs)]
    ^-  $@(brief:rudder action)
    ~
  ::
  ++  final  (alert:rudder (spat /apps/[dap.bowl]) build)
  ::
  ++  build
    |=  $:  arg=(list [k=@t v=@t])
            msg=(unit [o=? =@t])
        ==
    ^-  reply:rudder
    =/  raw=@t  (fall (~(get by (malt arg)) 'desk') '')
    =/  dex=(each desk tape)
      ?~  d=?:(=('' raw) ~ ((sand %tas) raw))
        |+"Give a desk to choose files from, as ?desk=name."
      ?.  (has-files:hc u.d)
        |+"There is no desk called %{(trip u.d)} with files to choose from."
      &+u.d
    [%page ~(page subset:w [bowl dex])]
  --
--
