::  pieces shared by deskjam's pages
::
/+  img=webui-images
|%
::  +banner: a page's message, if it has one
::
++  banner
  |=  msg=(unit [o=? =@t])
  ^-  marl
  ?~  msg  ~
  :_  ~
  ;p(class ?:(o.u.msg "ok" "bad")): {(trip t.u.msg)}
::
::  +tree: table rows showing files as a folder hierarchy under a desk
::
++  tree
  |=  [=desk hier=(list [pat=path dir=? dep=@])]
  ^-  marl
  %+  turn  hier
  |=  [pat=path dir=? dep=@]
  ^-  manx
  ;tr
    ;td
      ;table
        ;tr
          ;td(width (a-co:co (mul 20 dep)));
          ;td
            ;+  ?.  =(0 dep)
                  (resource-icon:img dir)
                ;p
                  ;strong: %
                ==
          ==
          ;td
            ;+  ?:  =(0 dep)  ;/  (trip desk)
                ?:  dir  ;/  (trip (rear pat))
                ;/  =/  end  (slag (sub (lent pat) 2) pat)
                    ?.  ?=([@ @ ~] end)  (spud pat)
                    "{(trip i.end)}.{(trip i.t.end)}"
          ==
        ==
      ==
    ==
  ==
--
