::  deskjam-url: urls as the runtime sends them
::
|%
::  +sendable: .url, escaped so that the runtime sends it as it is
::
::    the runtime parses a request's url with +de-purl:html, which
::    decodes the path and query, and sends the decoded text without
::    escaping it again. so escape what a browser would, and then the
::    path and query once more. ~ if the runtime can't parse the url,
::    which it then never answers.
::
++  sendable
  |=  url=@t
  ^-  (unit @t)
  =/  [ori=tape pax=tape qur=(unit tape)]  (parts url)
  ::  +de-purl:html can't parse an empty query field, which means
  ::  nothing anyway
  ::
  =/  args=(list tape)
    ?~  qur  ~
    %+  murn  (split '&' u.qur)
    |=  arg=tape
    ^-  (unit tape)
    ?:  =(~ arg)  ~
    ?~  tis=(find "=" arg)  `(escape arg)
    `:(weld (escape (scag u.tis arg)) "=" (escape (slag +(u.tis) arg)))
  =/  out=@t
    %-  crip
    ;:  weld
      ori
      ^-  tape
      %-  zing
      %+  turn  ?~(pax ~[~] (split '/' t.pax))
      |=(seg=tape ['/' (escape seg)])
      ^-  tape
      ?~(args ~ ['?' (zing (join "&" args))])
    ==
  ?~  (de-purl:html out)  ~
  `out
::
::  +parts: .url cut into its scheme and host, path and query, without
::  its #fragment, which is never sent
::
++  parts
  |=  url=@t
  ^-  [ori=tape pax=tape qur=(unit tape)]
  =/  tex=tape  (trip url)
  =.  tex  (scag (fall (find "#" tex) (lent tex)) tex)
  =/  hos=@ud  (fall (bind (find "://" tex) (cury add 3)) 0)
  =/  end=@ud
    =/  rest=tape  (slag hos tex)
    %+  add  hos
    (min (fall (find "/" rest) (lent rest)) (fall (find "?" rest) (lent rest)))
  =/  rest=tape  (slag end tex)
  ?~  wut=(find "?" rest)
    [(scag end tex) rest ~]
  [(scag end tex) (scag u.wut rest) `(slag +(u.wut) rest)]
::
::  +escape: .tex with what a browser would %-escape escaped, and then
::  all of it escaped again, for +de-purl:html to undo
::
++  escape
  |=  tex=tape
  ^-  tape
  %-  en-urlt:html
  %-  zing
  %+  turn  tex
  |=  c=@t
  ^-  tape
  ?.  ?|  (lte c ' ')
          (gte c 0x7f)
          !=(~ (find [c ~] (trip '"<>\\^`{|}')))
      ==
    [c ~]
  =/  hex  |=(n=@ ?:((gte n 10) (add n 55) (add n '0')))
  ['%' (hex (rsh [0 4] c)) (hex (end [0 4] c)) ~]
::
::  +split: .tex cut at each .sep
::
++  split
  |=  [sep=@t tex=tape]
  ^-  (list tape)
  =|  cur=tape
  =|  out=(list tape)
  |-
  ?~  tex  (flop [(flop cur) out])
  ?:  =(sep i.tex)
    $(tex t.tex, cur ~, out [(flop cur) out])
  $(tex t.tex, cur [i.tex cur])
--
