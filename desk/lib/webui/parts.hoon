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
::  +icons: the icons +tree's rows refer to, once per page
::
++  icons  `manx`symbols:img
::
::  +file-name: how to show a file at the end of its folder path
::
::    a file's last two segments are its name and mark. a hand-made
::    upload can have files with fewer.
::
++  file-name
  |=  pat=path
  ^-  tape
  =/  end=path
    ?:  (lth (lent pat) 2)  pat
    (slag (sub (lent pat) 2) pat)
  ?:  ?=([@ @ ~] end)  "{(short i.end)}.{(short i.t.end)}"
  ?:  ?=([@ ~] end)  (short i.end)
  "/"
::
::  +short: a path segment to show, cut short if it's long, as a
::  crafted upload's can be
::
++  short
  |=  seg=@t
  ^-  tape
  ?:  (lte (met 3 seg) 100)  (trip seg)
  (weld (trip (end [3 96] seg)) "...")
::
::  +more: a line saying how many files a list leaves out
::
++  more
  |=  n=@ud
  ^-  marl
  ?:  =(0 n)  ~
  :_  ~
  ;p: ...and {(a-co:co n)} more files, which deskjam doesn't list.
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
                ?:  dir  ;/  (short (rear pat))
                ;/  (file-name pat)
          ==
        ==
      ==
    ==
  ==
--
