|%
::  $mapp: a desk's files, as clay pages
::
+$  mapp  (map path page:clay)
+$  deskpack  [desk mapp]
::  $mode: what to do with an upload
::
::    %n: install it as a new desk
::    %r: replace a desk with it, deleting the files it lacks
::    %m: merge it into a desk, keeping the files it lacks
::
+$  mode  ?(%n %r %m)
+$  staged
  %-  unit
  $:  =stage=time
      =stage=desk
      =stage=mapp
  ==
::  $fetching: the url upload in progress, and why it failed if it did
::
+$  fetching  (unit [id=@da url=@t err=(unit @t)])
::  $sent: the desk last committed to, its revision before that,
::  whether clay is holding the commit for a newer kernel, and whether
::  the desk should be running after it
::
+$  sent  (unit [=desk rev=@ud held=? start=?])
+$  data
  $:  =staged
      dest=(unit [=mode =desk])
      =fetching
      =sent
  ==
+$  eyre-id  @ta
+$  action
  $%  [%stage-mapp =desk =mapp]
      [%url-thread url=@t]
      [%set-dest =mode =desk]
      [%commit revive=? pause=?]
      ::  %commit without options, for dests of mode %n and %m
      ::
      [%new-desk ~]
      [%add-files ~]
  ==
::  $plan: what committing the staged upload to a desk would do
::
+$  plan
  $:  =mode
      =desk                                             ::  target desk
      from=desk                                         ::  upload's own name
      exists=?                                          ::  target exists
      =zest:clay                                        ::  target's zest
      rev=@ud                                           ::  target's revision
      adds=(set path)                                   ::  files added
      puts=(set path)                                   ::  files changed
      same=(set path)                                   ::  files unchanged
      maybe=(set path)                                  ::  maybe changed
      dels=(set path)                                   ::  files deleted
      keeps=(set path)                                  ::  files left alone
      agents=(list dude:gall)                           ::  agents after
      source=(unit [=ship =desk])                       ::  kiln sync source
      live=?                                            ::  runs after commit
      held=?                                            ::  waits for a kernel
      revive=(unit @t)                                  ::  why it can't start
      errors=(list @t)                                  ::  stop the commit
      warnings=(list @t)                                ::  don't
  ==
--
