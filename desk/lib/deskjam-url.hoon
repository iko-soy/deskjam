::  deskjam-url: urls as the runtime sends them, and where requests to
::  deskjam come from
::
::    no ford runes, so tests can build it with just the standard library
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
::
::  +local: whether .url's host is this machine or a private network
::
::    a fetch could otherwise reach services that only trust the local
::    network, such as routers or the ship's own ports, and any url can
::    redirect to one, so fetches ask this on every hop. a name that
::    resolves to a private address still gets through: only the
::    runtime looks names up.
::
++  local
  |=  url=@t
  ^-  ?
  ::  judge the url as the runtime will request it
  ::
  ?~  pur=(biff (sendable url) de-purl:html)  |
  =*  hos  r.p.u.pur
  ?-    -.hos
      %|
    =/  a=@  (cut 3 [3 1] p.hos)
    =/  b=@  (cut 3 [2 1] p.hos)
    ?|  =(0 a)
        =(10 a)
        =(127 a)
        &(=(100 a) (gte b 64) (lte b 127))
        &(=(169 a) =(254 b))
        &(=(172 a) (gte b 16) (lte b 31))
        &(=(192 a) =(168 b))
    ==
  ::
      %&
    ::  the name's labels, top-level domain first
    ::
    =/  labs=(list @t)  p.hos
    ?~  labs  &
    ?~  t.labs  &
    ?|  ?=(?(%localhost %local %internal %lan %localdomain %localdomain4) i.labs)
        &(=('arpa' i.labs) =('home' i.t.labs))
        ::  no top-level domain starts with a digit: this is an address
        ::  in a form the runtime may still accept
        ::
        &((gte (end 3 i.labs) '0') (lte (end 3 i.labs) '9'))
    ==
  ==
::
::  +resolve: the absolute url a Location header sent for .base means
::
++  resolve
  |=  [base=@t loc=@t]
  ^-  @t
  ::  fragments are never sent
  ::
  =/  l=tape  (trip loc)
  =.  l  (scag (fall (find "#" l) (lent l)) l)
  ?:  =(~ l)  base
  =/  low=tape  (cass (scag 8 l))
  ?:  |(=("http://" (scag 7 low)) =("https://" low))  (crip l)
  ::  a url with another scheme stays as it is, for the fetch to refuse
  ::
  =/  colon=(unit @ud)  (find ":" l)
  ?:  ?&  ?=(^ colon)
          !=(0 u.colon)
          %+  levy  (scag u.colon l)
          |=  c=@t
          ?|  &((gte c 'a') (lte c 'z'))
              &((gte c 'A') (lte c 'Z'))
              &((gte c '0') (lte c '9'))
              ?=(?(%'+' %'-' %'.') c)
          ==
      ==
    (crip l)
  ::  .base is an absolute http(s) url: split off its scheme and host
  ::
  =/  b=tape  (trip base)
  =/  sep=@ud  (need (find "://" b))
  =/  rest=tape  (slag (add sep 3) b)
  ::  the host ends at the path, or at the query if there's no path
  ::
  =/  cut=@ud
    %+  min  (fall (find "/" rest) (lent rest))
    (fall (find "?" rest) (lent rest))
  =/  origin=tape  (scag (add (add sep 3) cut) b)
  ?:  =("//" (scag 2 l))  (crip (weld (scag (add sep 1) b) l))
  ?:  =("/" (scag 1 l))  (crip (weld origin l))
  ::  otherwise relative to .base's path, without its query
  ::
  =/  pax=tape  (slag cut rest)
  =.  pax  (scag (fall (find "?" pax) (lent pax)) pax)
  =?  pax  =(~ pax)  "/"
  ?:  =("?" (scag 1 l))  (crip :(weld origin pax l))
  =/  dir=tape
    =/  end=(unit @ud)  (find "/" (flop pax))
    ?~  end  "/"
    (scag (sub (lent pax) u.end) pax)
  (crip :(weld origin dir l))
::
::  +header: a response header, matching its name in any case
::
++  header
  |=  [key=@t hed=header-list:http]
  ^-  (unit @t)
  ?~  hed  ~
  ?:  =((cass (trip key)) (cass (trip key.i.hed)))
    `value.i.hed
  $(hed t.hed)
::
::  +cross-site: why to refuse a request, if a page on another origin
::  had the browser send it
::
::    any web page can make the browser post a form here, login cookie
::    and all, so take changes only from the ship's own pages. as go's
::    net/http CrossOriginProtection does, trust sec-fetch-site, which
::    browsers send to https and localhost urls. over plain http, and
::    from browsers older than 2023, only origin comes, which must then
::    match the host, as sent or as a proxy forwarded it. requests with
::    neither header are taken to be from scripts, not web pages.
::
++  cross-site
  |=  =request:http
  ^-  (unit tape)
  ?:  ?=(?(%'GET' %'HEAD') method.request)  ~
  =*  heds  header-list.request
  ?^  fetch=(get-header:http 'sec-fetch-site' heds)
    ?:  |(=('same-origin' u.fetch) =('none' u.fetch))  ~
    %-  some
    ;:  weld
      "deskjam only takes forms sent from your ship's own pages, and "
      "your browser says this one came from another site. To upload, "
      "open /apps/deskjam on your ship and use the form there."
    ==
  ?~  origin=(get-header:http 'origin' heds)  ~
  ::  an origin is a scheme, :// and a host, or else null
  ::
  =/  from=tape  (cass (trip u.origin))
  =/  host=tape  ?~(at=(find "://" from) ~ (slag (add 3 u.at) from))
  ?~  host
    %-  some
    ;:  weld
      "deskjam only takes forms sent from your ship's own pages, and "
      "your browser hid which page this one came from. Reach your ship "
      "over https, or let your browser send referrers to it."
    ==
  ::  where the browser could have reached the ship: the host as sent,
  ::  or as a proxy forwarded it, the browser's first if it lists more
  ::
  =/  ours=(list tape)
    %+  turn
      ;:  weld
        (drop (get-header:http 'host' heds))
        (drop (get-header:http 'x-forwarded-host' heds))
        =/  fwd  (biff (get-header:http 'forwarded' heds) unpack-header:http)
        ?.  ?=([~ ^] fwd)  ~
        (drop (~(get by i.u.fwd) 'host'))
      ==
    |=  hed=@t
    =/  hos=tape  (cass (trip hed))
    (scag (fall (find "," hos) (lent hos)) hos)
  ?:  (lien ours |=(hos=tape =(hos host)))  ~
  %-  some
  ;:  weld
    "deskjam only takes forms sent from your ship's own pages. This "
    "one came from a page at {(trip u.origin)}, but your ship was "
    "reached as {(trip (fall (get-header:http 'host' heds) '?'))}. If "
    "that page was deskjam's own, your ship is behind a reverse proxy "
    "that changes the Host header: make it pass on the Host the browser "
    "sent, or the browser's host in a Forwarded or X-Forwarded-Host "
    "header."
  ==
::
::  +cross-site-get: whether a GET or HEAD came from a page on another
::  site, as far as the browser says
::
::    over plain http browsers don't say, so this is only a hint: use it
::    to avoid side effects, never to protect anything
::
++  cross-site-get
  |=  =request:http
  ^-  ?
  ?~  fetch=(get-header:http 'sec-fetch-site' header-list.request)  |
  !|(=('same-origin' u.fetch) =('none' u.fetch))
--
