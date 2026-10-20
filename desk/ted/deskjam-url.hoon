::  deskjam-url: fetch a deskjam from a url, following redirects
::
/-  spider
/+  strandio, ju=deskjam-url
=,  strand=strand:spider
=>
|%
::  +fetch: the body of a successful GET of .url
::
++  fetch
  |=  [url=@t hops=@ud]
  =/  m  (strand ,@)
  ^-  form:m
  ::  the runtime silently drops requests for urls it can't parse
  ::
  ?~  out=(sendable:ju url)
    (fail %bad-url "it redirected to {(trip url)}, which can't be fetched")
  ::  follow redirects here, not in iris, which doesn't resolve
  ::  relative locations
  ::
  ;<  ~  bind:m
    %-  send-raw-card:strandio
    :*  %pass  /request  %arvo  %i  %request
        [%'GET' u.out ~ ~]
        `outbound-config:iris`[0 3]
    ==
  ;<  res=client-response:iris  bind:m
    %+  (map-err:strandio client-response:iris)
      |=  [=term =tang]
      ?.  =(%timeout term)  [term tang]
      [term leaf+"the server didn't answer within 10 minutes" tang]
    ((set-timeout:strandio client-response:iris) ~m10 take-client-response:strandio)
  ?>  ?=(%finished -.res)
  =*  code  status-code.response-header.res
  ?:  &((gte code 300) (lth code 400))
    ?:  =(0 hops)
      (fail %too-many-redirects "it redirected too many times")
    ?~  loc=(header 'location' headers.response-header.res)
      (fail %no-location "it redirected without saying where to")
    (fetch (resolve url u.loc) (dec hops))
  ?:  =(504 code)
    (fail %bad-status "the server didn't answer (HTTP 504)")
  ?.  =(200 code)
    (fail %bad-status "the server answered HTTP {(a-co:co code)}")
  ?~  full-file.res
    (fail %no-body "the server sent no file")
  (pure:m q.data.u.full-file.res)
::
++  fail
  |=  [=term =tape]
  =/  m  (strand ,@)
  ^-  form:m
  (strand-fail:strand term leaf+tape ~)
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
  ::  a url with another scheme stays as it is, for +fetch to refuse
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
  =/  cut=@ud  (fall (find "/" rest) (lent rest))
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
--
^-  thread:spider
|=  arg=vase
=/  m  (strand ,vase)
^-  form:m
;<  dat=@  bind:m  (fetch (need !<((unit @t) arg)) 5)
(pure:m !>(dat))
