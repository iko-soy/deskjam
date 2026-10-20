::  tests for /lib/deskjam-url.hoon
::
::    run.sh puts this after the library, so its arms are in scope. each
::    check is a label and a ?>: a failing check crashes the run, which
::    then prints the labels of the checks up to it, the failing one
::    last. a run that gets through them all ends in %tests-passed.
::
::  +sendable: escape a url so that the runtime, which decodes %XX
::  before sending, sends it as written
::
~|  'sendable: %20 in a path'
?>  =(`'https://example.com/a%2520b' (sendable 'https://example.com/a%20b'))
~|  'sendable: a space in a path'
?>  =(`'https://example.com/a%2520b' (sendable 'https://example.com/a b'))
~|  'sendable: + in a query'
?>  =(`'https://example.com/a?x=1%2B2' (sendable 'https://example.com/a?x=1+2'))
~|  'sendable: %2B in a query'
?>  =(`'https://example.com/a?x=1%252B2' (sendable 'https://example.com/a?x=1%2B2'))
~|  'sendable: %2F in a path stays an escape'
?>  =(`'https://example.com/a%252Fb' (sendable 'https://example.com/a%2Fb'))
~|  'sendable: utf-8 in a path'
?>  =(`'https://example.com/caf%25C3%25A9' (sendable 'https://example.com/caf\c3\a9'))
~|  'sendable: spaces in query keys and values'
?>  .=  `'http://example.com:8080/a%2520b?c%2520d=e%2520f'
    (sendable 'http://example.com:8080/a b?c d=e f')
~|  'sendable: a github release url is unchanged'
?>  .=  `'https://github.com/iko-soy/deskjam/releases/download/v0.2.1/deskjam.deskjam'
    (sendable 'https://github.com/iko-soy/deskjam/releases/download/v0.2.1/deskjam.deskjam')
~|  'sendable: the fragment is dropped'
?>  =(`'https://example.com/a' (sendable 'https://example.com/a#frag'))
~|  'sendable: an empty query is dropped'
?>  =(`'https://example.com/a' (sendable 'https://example.com/a?'))
~|  'sendable: an empty query before a fragment is dropped'
?>  =(`'https://example.com/a' (sendable 'https://example.com/a?#frag'))
~|  'sendable: empty query fields are dropped'
?>  =(`'https://example.com/a?x=1&y=2' (sendable 'https://example.com/a?x=1&&y=2&'))
~|  'sendable: a bare host gets a path'
?>  =(`'https://example.com/' (sendable 'https://example.com'))
~|  'sendable: a query on a bare host'
?>  =(`'https://example.com/?q=1' (sendable 'https://example.com?q=1'))
~|  'sendable: ftp'
?>  =(~ (sendable 'ftp://example.com/x'))
~|  'sendable: no scheme'
?>  =(~ (sendable 'example.com/a'))
~|  'sendable: a host with a space'
?>  =(~ (sendable 'https://exa mple.com/'))
::  what the runtime then sends: the url as written
::
~|  'sendable: the runtime decodes %2520 to %20'
?>  .=  ~['a%20b']
    q.q:(need (de-purl:html (need (sendable 'https://example.com/a%20b'))))
~|  'sendable: the runtime decodes the query to what a browser sends'
?>  .=  ~[['x' '1%2B2'] ['y' 'a%20b']]
    r:(need (de-purl:html (need (sendable 'https://example.com/a?x=1%2B2&y=a b'))))
::
::  +parts and +split
::
~|  'parts: scheme and host, path, query, no fragment'
?>  .=  ["https://example.com:8080" "/p/q" `"r=s"]
    (parts 'https://example.com:8080/p/q?r=s#frag')
~|  'parts: a bare host'
?>  =(["https://example.com" "" ~] (parts 'https://example.com'))
~|  'split: empty fields'
?>  =(~["a" "" "b"] (split '&' "a&&b"))
~|  'split: nothing to split'
?>  =(~[""] (split '/' ""))
::
::  +resolve: where a Location header points, from the url that sent it
::
=/  base  'https://a.com/x/y'
~|  'resolve: an absolute url'
?>  =('https://b.com/z' (resolve base 'https://b.com/z'))
~|  'resolve: an absolute url with an uppercase scheme'
?>  =('HTTP://b.com/z' (resolve base 'HTTP://b.com/z'))
~|  'resolve: an absolute url loses its fragment'
?>  =('https://b.com/z' (resolve base 'https://b.com/z#f'))
~|  'resolve: scheme-relative'
?>  =('https://b.com/z' (resolve base '//b.com/z'))
~|  'resolve: scheme-relative from http'
?>  =('http://b.com/z' (resolve 'http://a.com:8080/x/y' '//b.com/z'))
~|  'resolve: root-relative'
?>  =('https://a.com/z' (resolve base '/z'))
~|  'resolve: root-relative keeps the port'
?>  =('http://a.com:8080/z' (resolve 'http://a.com:8080/x/y' '/z'))
~|  'resolve: relative'
?>  =('https://a.com/x/z' (resolve base 'z'))
~|  'resolve: relative to a directory'
?>  =('https://a.com/x/z' (resolve 'https://a.com/x/' 'z'))
~|  'resolve: relative to a bare host'
?>  =('https://a.com/z' (resolve 'https://a.com' 'z'))
~|  'resolve: relative to a bare host with a query'
?>  ?&  =('https://a.com/z' (resolve 'https://a.com?k=v' 'z'))
        =('https://a.com/z' (resolve 'https://a.com?k=v' '/z'))
        =('https://a.com/?q' (resolve 'https://a.com?k=v' '?q'))
    ==
~|  'resolve: relative, without the base query'
?>  =('https://a.com/x/z' (resolve 'https://a.com/x/y?old=1' 'z'))
~|  'resolve: relative, without its fragment'
?>  =('https://a.com/x/z' (resolve base 'z#frag'))
~|  'resolve: relative with a colon after a slash'
?>  =('https://a.com/x/a/b:c' (resolve base 'a/b:c'))
~|  'resolve: a query only'
?>  =('https://a.com/x/y?q' (resolve base '?q'))
~|  'resolve: a query only, replacing the base query'
?>  =('https://a.com/x/y?q' (resolve 'https://a.com/x/y?old=1' '?q'))
~|  'resolve: a query only, on a bare host'
?>  =('https://a.com/?q' (resolve 'https://a.com' '?q'))
~|  'resolve: other schemes stay as they are'
?>  ?&  =('ftp://b.com/z' (resolve base 'ftp://b.com/z'))
        =('mailto:x@y' (resolve base 'mailto:x@y'))
    ==
~|  'resolve: an empty location is the base'
?>  =(base (resolve base ''))
~|  'resolve: a fragment only is the base'
?>  =(base (resolve base '#frag'))
::
::  +header: a response header, by name in any case
::
~|  'header: any case'
?>  ?&  =(`'/x' (header 'location' ~[['Location' '/x']]))
        =(`'/x' (header 'Location' ~[['location' '/x']]))
        =(`'/x' (header 'LOCATION' ~[['content-type' 'text/plain'] ['LoCaTiOn' '/x']]))
    ==
~|  'header: the first of several'
?>  =(`'a' (header 'content-type' ~[['Content-Type' 'a'] ['content-type' 'b']]))
~|  'header: missing'
?>  ?&  =(~ (header 'location' ~[['content-type' 'text/plain']]))
        =(~ (header 'location' ~))
    ==
::
::  +local: hosts that are this machine or a private network
::
=/  locals=(list @t)
  :~  'http://127.0.0.1/'
      'http://127.0.0.1:8080/x'
      'HTTP://127.0.0.1/'
      'http://10.1.2.3/'
      'http://100.64.0.1/'
      'http://100.127.255.255/'
      'http://169.254.169.254/latest/meta-data/'
      'http://172.16.0.1/'
      'http://172.31.255.255/'
      'http://192.168.1.1/'
      'http://0.0.0.0/'
      'http://localhost/'
      'http://localhost:8080/'
      'http://intranet/'
      'http://foo.localhost/'
      'http://router.lan/'
      'http://x.home.arpa/'
      'http://printer.local/'
      'http://a.internal/'
  ==
=/  publics=(list @t)
  :~  'http://example.com/'
      'https://github.com/iko-soy/deskjam/releases/download/v0.2.1/deskjam.deskjam'
      'https://objects.githubusercontent.com/github-production-release-asset/1'
      'http://8.8.8.8/'
      'http://1.1.1.1/'
      'http://11.0.0.1/'
      'http://100.63.255.255/'
      'http://100.128.0.1/'
      'http://169.253.1.1/'
      'http://172.15.255.255/'
      'http://172.32.0.1/'
      'http://192.169.1.1/'
      'http://in-addr.arpa/'
      ::  only the runtime resolves names
      ::
      'http://127.0.0.1.nip.io/'
      ::  the runtime can't parse these, so never fetches them
      ::
      'not a url'
      'ftp://127.0.0.1/'
  ==
~|  'local: loopback, private, link-local, cgnat and local names'
?>  (levy locals local)
~|  'local: public addresses and names, and unparseable urls'
?>  (levy publics |=(u=@t !(local u)))
::  +local judges the url the runtime requests: +sendable's, which
::  escapes what de-purl can't parse in the raw url
::
~|  'local: urls with characters only sendable escapes'
?>  ?&  (local 'http://127.0.0.1/foo bar')
        (local 'http://192.168.1.1/admin|x')
        (local 'http://10.0.0.1/%zz')
        (local 'http://127.0.0.1/x.deskjam#f')
        (local (resolve 'https://evil.example/x.deskjam' 'http://192.168.1.1/cgi-bin/reboot?a=%zz'))
    ==
~|  'local: localdomain names'
?>  ?&  (local 'http://localhost.localdomain/')
        (local 'http://a.localhost.localdomain/')
        (local 'http://x.localdomain4/')
    ==
::
::  +cross-site: why to refuse a request another site's page sent
::
=/  req
  |=  [met=method:http hed=(list [@t @t])]
  ^-  request:http
  [met '/apps/deskjam' hed ~]
=/  post  |=(hed=(list [@t @t]) (req %'POST' hed))
=/  ok  |=(r=request:http =(~ (cross-site r)))
~|  'cross-site: GET and HEAD are exempt'
?>  ?&  (ok (req %'GET' ~[['sec-fetch-site' 'cross-site']]))
        (ok (req %'HEAD' ~[['origin' 'http://evil.example'] ['host' 'zod.local']]))
    ==
~|  'cross-site: other methods are not'
?>  ?&  !(ok (req %'PUT' ~[['origin' 'http://evil.example'] ['host' 'zod.local']]))
        !(ok (req %'DELETE' ~[['sec-fetch-site' 'cross-site']]))
    ==
~|  'cross-site: sec-fetch-site same-origin and none pass'
?>  ?&  (ok (post ~[['sec-fetch-site' 'same-origin']]))
        (ok (post ~[['sec-fetch-site' 'none']]))
    ==
~|  'cross-site: sec-fetch-site cross-site and same-site are refused'
?>  ?&  !(ok (post ~[['sec-fetch-site' 'cross-site']]))
        !(ok (post ~[['sec-fetch-site' 'same-site']]))
    ==
~|  'cross-site: sec-fetch-site wins over origin'
?>  ?&  (ok (post ~[['sec-fetch-site' 'same-origin'] ['origin' 'http://evil.example'] ['host' 'zod.local']]))
        !(ok (post ~[['sec-fetch-site' 'cross-site'] ['origin' 'http://zod.local'] ['host' 'zod.local']]))
    ==
~|  'cross-site: no sec-fetch-site or origin passes'
?>  ?&  (ok (post ~))
        (ok (post ~[['host' 'zod.local:8080']]))
    ==
~|  'cross-site: origin matching host, with its port'
?>  (ok (post ~[['origin' 'http://zod.local:8080'] ['host' 'zod.local:8080']]))
~|  'cross-site: origin matching host, in any case'
?>  (ok (post ~[['origin' 'http://ZOD.local:8080'] ['host' 'zod.LOCAL:8080']]))
~|  'cross-site: origin and host with different ports'
?>  ?&  !(ok (post ~[['origin' 'http://zod.local:8080'] ['host' 'zod.local']]))
        !(ok (post ~[['origin' 'http://zod.local'] ['host' 'zod.local:8080']]))
    ==
~|  'cross-site: origin matching x-forwarded-host'
?>  (ok (post ~[['origin' 'https://ship.example'] ['host' '127.0.0.1:8080'] ['x-forwarded-host' 'ship.example']]))
~|  'cross-site: the first x-forwarded-host counts'
?>  ?&  (ok (post ~[['origin' 'https://ship.example'] ['host' '127.0.0.1:8080'] ['x-forwarded-host' 'ship.example, proxy.internal']]))
        !(ok (post ~[['origin' 'https://ship.example'] ['host' '127.0.0.1:8080'] ['x-forwarded-host' 'proxy.internal, ship.example']]))
    ==
~|  'cross-site: origin matching the host in forwarded'
?>  ?&  (ok (post ~[['origin' 'https://ship.example'] ['host' '127.0.0.1:8080'] ['forwarded' 'host="ship.example"']]))
        (ok (post ~[['origin' 'https://ship.example'] ['host' '127.0.0.1:8080'] ['forwarded' 'for=192.0.2.1;host=ship.example;proto=https']]))
    ==
~|  'cross-site: only the first forwarded element counts'
?>  !(ok (post ~[['origin' 'https://ship.example'] ['host' '127.0.0.1:8080'] ['forwarded' 'host="other.example", host="ship.example"']]))
~|  'cross-site: a forwarded header without a host'
?>  ?&  !(ok (post ~[['origin' 'https://ship.example'] ['host' '127.0.0.1:8080'] ['forwarded' 'for=192.0.2.1']]))
        !(ok (post ~[['origin' 'https://ship.example'] ['host' '127.0.0.1:8080'] ['forwarded' 'garbage;;;']]))
    ==
~|  'cross-site: origin null is refused'
?>  !(ok (post ~[['origin' 'null'] ['host' 'zod.local']]))
~|  'cross-site: another origin is refused'
?>  ?&  !(ok (post ~[['origin' 'http://evil.example'] ['host' 'zod.local:8080']]))
        !(ok (post ~[['origin' 'http://evil.example']]))
        !(ok (post ~[['origin' 'http://zod.local:8080.evil.example'] ['host' 'zod.local:8080']]))
    ==
::
::  +cross-site-get: whether a GET says it came from another site
::
~|  'cross-site-get: another site'
?>  ?&  (cross-site-get (req %'GET' ~[['sec-fetch-site' 'cross-site']]))
        (cross-site-get (req %'GET' ~[['sec-fetch-site' 'same-site']]))
        (cross-site-get (req %'HEAD' ~[['sec-fetch-site' 'cross-site']]))
    ==
~|  'cross-site-get: this site, or unknown'
?>  ?&  !(cross-site-get (req %'GET' ~[['sec-fetch-site' 'same-origin']]))
        !(cross-site-get (req %'GET' ~[['sec-fetch-site' 'none']]))
        !(cross-site-get (req %'GET' ~))
        !(cross-site-get (req %'GET' ~[['origin' 'http://evil.example'] ['host' 'zod.local']]))
    ==
%tests-passed
