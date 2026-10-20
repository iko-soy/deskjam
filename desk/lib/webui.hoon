/-  *deskjam
/+  rudder, multipart, w=webui-pages, h=deskjam
/$  deskjam-to-deskpack-0  %deskjam  %deskpack-0
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
    [%subset ~]   subset
    [%status ~]   status
  ==
::
++  index
  |_  [=bowl:gall * =data]
  +*  hc  ~(. h [our now]:bowl)
  ++  argue
    |=  [headers=header-list:http body=(unit octs)]
    ^-  $@(brief:rudder action)
    =/  parts  (de-request:multipart headers body)
    ?~  parts
      =/  args=(map @t @t)
        ?~(body ~ (frisk:rudder q.u.body))
      ?~  url=(~(get by args) 'url')  'Give a url to fetch.'
      [%url-thread u.url]
    =/  jam=(unit jam)
      %-  lint:hc
      ^-  (list jam)
      %+  murn  u.parts
      |=  [n=@t p=part:multipart]
      ^-  (unit jam)
      ?+  n  ~
        %file  [~ `jam`body:p]
      ==
    ?~  jam  'Choose a file to upload.'
    ?~  pack=(mole |.((deskjam-to-deskpack-0 u.jam)))
      'That file isn\'t a deskjam.'
    [%stage-mapp u.pack]
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
    [%page ~(page index:w [bowl data msg])]
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
    [%page ~(page staged:w [bowl data msg])]
  --
::
++  confirm
  |_  [=bowl:gall * =data]
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
    ::  if the form says what it showed, refuse to commit anything else
    ::
    =/  shown=(list (unit @t))
      (turn ~['mode' 'desk' 'upload'] ~(get by args))
    =/  now=(list (unit @t))
      :~  (bind dest.data |=([=mode =desk] `@t`mode))
          (bind dest.data |=([=mode =desk] `@t`desk))
          (bind staged.data |=([=time *] (scot %da time)))
      ==
    ::  (with nothing staged, the commit says what happened instead)
    ::
    ?:  ?&  ?=(^ staged.data)
            (lien shown |=(a=(unit @t) ?=(^ a)))
            !=(shown now)
        ==
      'The upload or its destination changed after this page was shown. Check them again, then confirm.'
    [%commit (~(has by args) 'revive') (~(has by args) 'pause')]
  ::
  ::  after a commit, show the desk it went to
  ::
  ++  final
    |=  [done=? =brief:rudder]
    ^-  reply:rudder
    ?.  done  (build ~ `[| `@t`brief])
    =/  dex=@t  ?~(sent.data %$ desk.u.sent.data)
    [%next (rap 3 (spat /apps/[dap.bowl]/status) '?desk=' dex ~) brief]
  ::
  ++  build
    |=  $:  arg=(list [k=@t v=@t])
            msg=(unit [o=? =@t])
        ==
    ^-  reply:rudder
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
    =/  raw=(unit @t)
      =/  got  (~(get by (malt arg)) 'desk')
      ?:(=([~ ''] got) ~ got)
    =/  dex=(unit desk)  (biff raw (sand %tas))
    =?  msg  &(?=(^ raw) ?=(~ dex))
      `[| (crip "%{(trip u.raw)} isn't a valid desk name.")]
    [%page ~(page status:w [bowl data dex msg])]
  --
::
++  subset
  |_  [=bowl:gall * data]
  +*  hc  ~(. h [our now]:bowl)
  ++  argue
    |=  [headers=header-list:http body=(unit octs)]
    ^-  $@(brief:rudder action)
    =/  args=(map @t @t)
      ?~(body ~ (frisk:rudder q.u.body))
    =/  pax=(list path)
      (turn ~(tap in ~(key by args)) (curr rash stap))
    :: ~&  (turn pax spat)
    ~
  ::
  ++  final  (alert:rudder (spat /apps/[dap.bowl]) build)
  ::
  ++  build
    |=  $:  arg=(list [k=@t v=@t])
            msg=(unit [o=? =@t])
        ==
    ^-  reply:rudder
    =/  dex=desk
      %-  need
      %-  (sand %tas)
      (~(got by (~(gas by *(map @t @t)) arg)) 'desk')
    [%page ~(page subset:w [bowl dex])]
  --
--
