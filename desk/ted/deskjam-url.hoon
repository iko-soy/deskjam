::  deskjam-url: fetch a deskjam from a url, following redirects
::
::    takes (unit [url=@t local=?]): .local lets it fetch from this
::    machine or the local network
::
/-  spider
/+  strandio, ju=deskjam-url
=,  strand=strand:spider
=>
|%
::  +fetch: the body of a successful GET of .url, got before .end
::
++  fetch
  |=  [url=@t hops=@ud end=@da local=?]
  =/  m  (strand ,@)
  ^-  form:m
  ::  the runtime silently drops requests for urls it can't parse
  ::
  ::  only the first hop's url is the user's own; a redirect's comes from
  ::  the server, so don't repeat it
  ::
  ?~  out=(sendable:ju url)
    (fail %bad-url "it redirected to a url that deskjam can't fetch")
  ?:  &(!local (local:ju url))
    %+  fail  %local
    "it redirected to an address on this machine or your local network, which deskjam doesn't follow from elsewhere"
  ;<  now=@da  bind:m  get-time:strandio
  ?:  (gte now end)
    (fail %timeout "the server didn't answer within 10 minutes")
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
    %+  (set-timeout:strandio client-response:iris)
      (sub end now)
    take-client-response:strandio
  ?>  ?=(%finished -.res)
  =*  code  status-code.response-header.res
  ?:  &((gte code 300) (lth code 400))
    ?:  =(0 hops)
      (fail %too-many-redirects "it redirected too many times")
    ?~  loc=(header:ju 'location' headers.response-header.res)
      (fail %no-location "it redirected without saying where to")
    (fetch (resolve:ju url u.loc) (dec hops) end local)
  ::  the runtime also answers 504 when it can't look up the host, or
  ::  connect to it at all
  ::
  ?:  =(504 code)
    (fail %bad-status "the server couldn't be reached (HTTP 504). Check the url's host name, or try again later")
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
--
^-  thread:spider
|=  arg=vase
=/  m  (strand ,vase)
^-  form:m
=/  [url=@t local=?]  (need !<((unit [@t ?]) arg))
;<  now=@da  bind:m  get-time:strandio
;<  dat=@  bind:m  (fetch url 5 (add now ~m10) local)
(pure:m !>(dat))
