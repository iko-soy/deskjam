::  deskjam-guard: checks that keep a crafted upload from hanging the ship
::
::    deskjam unpacks and reads an upload before anyone confirms it, and
::    the event that does so runs until it finishes: catching crashes
::    doesn't stop a computation that never ends.
::
|%
::  +bounded: whether .non has at most .gas cells, counting a shared
::  subtree each time it occurs
::
::    jam's backreferences let a small file unpack to a noun whose tree
::    is exponentially larger than the file, and every mold that checks
::    a noun's shape walks it as a tree. so count the tree's cells
::    first, giving up as soon as there are too many.
::
++  bounded
  |=  [gas=@ud non=*]
  ^-  ?
  ?=(^ (spend gas non))
::
::  +spend: .gas less the cells of .non, or ~ if it runs out
::
::    with a list of subtrees still to count, not recursion, so a deep
::    noun can't exhaust the stack
::
++  spend
  |=  [gas=@ud non=*]
  ^-  (unit @ud)
  =/  todo=(list *)  ~[non]
  |-  ^-  (unit @ud)
  ?~  todo  `gas
  ?@  i.todo  $(todo t.todo)
  ?:  =(0 gas)  ~
  $(gas (dec gas), todo [-.i.todo +.i.todo t.todo])
::
::  +budget: the gas to unpack a jam of .bits bits with
::
::    a real deskjam has far fewer cells than bits, and the cap keeps a
::    big file that is mostly padding from buying a long walk
::
++  budget  |=(bits=@ud (min bits (bex 22)))
::
::  reading literal hoon
::
::    clay reads /desk/bill, /desk/docket-0 and /sys/kelvin by parsing
::    them as hoon and evaluating them. hoon's parser can take
::    exponential time on crafted text, and evaluation can loop forever,
::    so deskjam reads an upload's copies with +read instead: one pass
::    over the text, taking only the literals that real files use,
::    nested a few levels deep at most. anything else reads as ~.
::
::    it takes, as hoon does: 'cords' with \\, \' and \xx escapes, %terms,
::    numbers (408, 1.000, 0x9c.cfe7, 0v1.abcde, 0w and 0b too), ~ships,
::    ~, /paths of terms, [wide tuples], ~[wide lists], tall :~ lists
::    closed by ==, term+value pairs, and :: comments.
::
::  +read: the values .tex spells out, separated by whitespace
::
++  read
  |=  tex=@t
  ^-  (unit (list *))
  ?:  (gth (met 3 tex) 262.144)  ~
  =/  cs=tape  (trip tex)
  =|  rev=(list *)
  |-  ^-  (unit (list *))
  =.  cs  cs:(skip cs)
  ?~  cs  `(flop rev)
  ?~  got=(value cs 0)  ~
  ?.  |(?=(~ q.u.got) (white i.q.u.got))  ~
  $(cs q.u.got, rev [p.u.got rev])
::
::  +read-one: the one value .tex spells out
::
++  read-one
  |=  tex=@t
  ^-  (unit *)
  =/  all  (read tex)
  ?.  ?=([~ [* ~]] all)  ~
  `i.u.all
::
++  value
  |=  [cs=tape dep=@ud]
  ^-  (unit [p=* q=tape])
  ?~  cs  ~
  ?:  (gth dep 8)  ~
  ?:  =('\'' i.cs)  (lit-cord t.cs)
  ?:  =('%' i.cs)  (lit-term t.cs)
  ?:  =('[' i.cs)  (wide t.cs +(dep) |)
  ?:  =('/' i.cs)  (lit-path t.cs)
  ?:  =('~' i.cs)  (sig t.cs +(dep))
  ?:  =(':' i.cs)  (tall cs +(dep))
  ?:  (lower i.cs)  (lit-pair cs +(dep))
  ?:  (digit i.cs)  (number cs)
  ~
::
::  +skip: .cs past whitespace and :: comments, and whether they made a
::  gap, which tall forms need: two spaces, or a newline
::
++  skip
  |=  cs=tape
  ^-  [gap=? cs=tape]
  =/  n=@ud  0
  =/  nl=?  |
  |-  ^-  [gap=? cs=tape]
  ?~  cs  [|((gte n 2) nl) ~]
  ?:  =(' ' i.cs)  $(cs t.cs, n +(n))
  ?:  =('\0a' i.cs)  $(cs t.cs, nl &)
  ?:  &(=(':' i.cs) ?=(^ t.cs) =(':' i.t.cs))
    $(cs ?~(e=(find "\0a" `tape`cs) ~ (slag +(u.e) `tape`cs)), nl &)
  [|((gte n 2) nl) cs]
::
++  white  |=(c=@ |(=(' ' c) =('\0a' c)))
++  lower  |=(c=@ &((gte c 'a') (lte c 'z')))
++  digit  |=(c=@ &((gte c '0') (lte c '9')))
++  sym    |=(c=@ |((lower c) (digit c) =('-' c)))
::
::  +take: the run of up to .max characters at the start of .cs that
::  pass .ok, and the rest; ~ if the run is longer
::
++  take
  |=  [cs=tape ok=$-(@ ?) max=@ud]
  ^-  (unit [tape tape])
  =|  rev=tape
  |-  ^-  (unit [tape tape])
  ?:  &(?=(^ cs) (ok i.cs))
    ?:  =(0 max)  ~
    $(cs t.cs, rev [i.cs rev], max (dec max))
  `[(flop rev) cs]
::
::  +lit-cord: a 'cord', after its opening quote
::
++  lit-cord
  |=  cs=tape
  ^-  (unit [p=* q=tape])
  ::  ''' starts a block of lines, which real files don't use
  ::
  ?:  ?=([%'\'' %'\'' *] cs)  ~
  =|  rev=tape
  |-  ^-  (unit [p=* q=tape])
  ?~  cs  ~
  ?:  =('\'' i.cs)  `[(crip (flop rev)) t.cs]
  ?.  =('\\' i.cs)
    ?:  |((lth i.cs 32) =(127 i.cs))  ~
    $(cs t.cs, rev [i.cs rev])
  ?:  ?=([?(%'\\' %'\'') *] t.cs)
    $(cs t.t.cs, rev [i.t.cs rev])
  ?.  ?=([@ @ *] t.cs)  ~
  ?~  hi=(hexit i.t.cs)  ~
  ?~  lo=(hexit i.t.t.cs)  ~
  $(cs t.t.t.cs, rev [(add (mul 16 u.hi) u.lo) rev])
::
++  hexit
  |=  c=@
  ^-  (unit @)
  ?:  (digit c)  `(sub c '0')
  ?:  &((gte c 'a') (lte c 'f'))  `(add 10 (sub c 'a'))
  ~
::
::  +lit-term: a %term, after its %
::
++  lit-term
  |=  cs=tape
  ^-  (unit [p=* q=tape])
  ?.  &(?=(^ cs) (lower i.cs))  ~
  ?~  got=(take cs sym 256)  ~
  `[(crip -.u.got) +.u.got]
::
::  +lit-pair: term+value, as hoon reads [%term value]
::
++  lit-pair
  |=  [cs=tape dep=@ud]
  ^-  (unit [p=* q=tape])
  ?~  got=(take cs sym 256)  ~
  =/  [tok=tape rest=tape]  u.got
  ?.  ?=([%'+' *] rest)  ~
  ?~  val=(value t.rest dep)  ~
  `[[(crip tok) p.u.val] q.u.val]
::
::  +lit-path: a /path of terms, after its first /; / alone is ~
::
++  lit-path
  |=  cs=tape
  ^-  (unit [p=* q=tape])
  ?.  &(?=(^ cs) (lower i.cs))  `[~ cs]
  =/  more=tape  cs
  =|  rev=(list @)
  |-  ^-  (unit [p=* q=tape])
  ::  hoon reads a segment that doesn't start with a letter as some
  ::  other literal, such as a number
  ::
  ?.  &(?=(^ more) (lower i.more))  ~
  ?~  got=(take more sym 256)  ~
  =/  [seg=tape rest=tape]  u.got
  =.  rev  [(crip seg) rev]
  ?.  ?=([%'/' *] rest)  `[(flop rev) rest]
  $(more t.rest)
::
::  +number: 408, 1.000, 0x9c.cfe7, 0v1.abcde, as their auras write them
::
++  number
  |=  cs=tape
  ^-  (unit [p=* q=tape])
  ?~  got=(take cs |=(c=@ |((lower c) (digit c) =('.' c))) 128)  ~
  =/  [tok=tape rest=tape]  u.got
  =/  aur=@tas
    ?+  tok  %ud
      [%'0' %'x' *]  %ux
      [%'0' %'v' *]  %uv
      [%'0' %'w' *]  %uw
      [%'0' %'b' *]  %ub
    ==
  ?~  n=(slaw aur (crip tok))  ~
  `[u.n rest]
::
::  +sig: what starts with ~: ~, a ~ship, or a ~[wide list]
::
++  sig
  |=  [cs=tape dep=@ud]
  ^-  (unit [p=* q=tape])
  ?:  ?=([%'[' *] cs)  (wide t.cs dep &)
  ?.  &(?=(^ cs) (lower i.cs))  `[~ cs]
  ?~  got=(take cs |=(c=@ |((lower c) =('-' c))) 64)  ~
  ?~  who=(slaw %p (crip ['~' -.u.got]))  ~
  `[u.who +.u.got]
::
::  +wide: [a b c] after its [, values separated by single spaces; as a
::  ~[list] if .lis
::
++  wide
  |=  [cs=tape dep=@ud lis=?]
  ^-  (unit [p=* q=tape])
  =|  rev=(list *)
  |-  ^-  (unit [p=* q=tape])
  ?~  got=(value cs dep)  ~
  =.  rev  [p.u.got rev]
  =*  rest  q.u.got
  ?~  rest  ~
  ?:  =(']' i.rest)  `[(nest rev lis) t.rest]
  ?.  =(' ' i.rest)  ~
  $(cs t.rest)
::
::  +tall: a :~ list closed by ==, at least one value, separated by gaps
::
++  tall
  |=  [cs=tape dep=@ud]
  ^-  (unit [p=* q=tape])
  ?.  ?=([%':' %'~' *] cs)  ~
  =/  sep  (skip t.t.cs)
  ?.  gap.sep  ~
  =/  rest=tape  cs.sep
  =|  rev=(list *)
  |-  ^-  (unit [p=* q=tape])
  ?:  ?=([%'=' %'=' *] rest)
    ?~  rev  ~
    `[(nest rev &) t.t.rest]
  ?~  got=(value rest dep)  ~
  =.  sep  (skip q.u.got)
  ?.  gap.sep  ~
  $(rest cs.sep, rev [p.u.got rev])
::
::  reading ford headers
::
::    the imports at the top of a hoon file, as clay's ford reads them,
::    so deskjam can check that a desk has every file its marks and
::    agents need before clay refuses the commit for a missing one. one
::    pass over the text. ~ for a header deskjam can't read, such as
::    one with /~, whose files it then doesn't check.
::
+$  imports
  $:  sur=(list @t)                                     ::  /-  names
      lib=(list @t)                                     ::  /+  names
      raw=(list path)                                   ::  /=  hoon files
      maz=(list @t)                                     ::  /%  marks
      caz=(list [@t @t])                                ::  /$  conversions
      bar=(list [@t path])                              ::  /*  mark, file
  ==
::
::  +read-imports: a hoon file's imports
::
++  read-imports
  |=  tex=@t
  ^-  (unit imports)
  =/  cs=tape  (trip (end [3 65.536] tex))
  =|  out=imports
  =.  cs  cs:(skip cs)
  ::  /?  and a version, which ford ignores
  ::
  =?  cs  &(?=(^ cs) =('/' i.cs) ?=(^ t.cs) =('?' i.t.cs))
    ?~(e=(find "\0a" `tape`cs) ~ (slag +(u.e) `tape`cs))
  |-  ^-  (unit imports)
  =.  cs  cs:(skip cs)
  ?.  &(?=(^ cs) =('/' i.cs) ?=(^ t.cs))  `(forward out)
  =/  run=@  i.t.cs
  =/  one  (skip t.t.cs)
  ?.  gap.one  `(forward out)
  =/  rest=tape  cs.one
  ?:  |(=('-' run) =('+' run))
    ?~  got=(tauts rest)  ~
    =?  sur.out  =('-' run)  (weld (flop -.u.got) sur.out)
    =?  lib.out  =('+' run)  (weld (flop -.u.got) lib.out)
    $(cs +.u.got)
  ::  the other runes start with a face
  ::
  ?~  face=(take rest sym 256)  ~
  =/  two  (skip +.u.face)
  ?.  gap.two  ~
  =/  more=tape  cs.two
  ?:  =('=' run)
    ?~  pax=(knots more)  ~
    $(cs +.u.pax, raw.out [-.u.pax raw.out])
  ?:  =('%' run)
    ?~  mak=(mark-at more)  ~
    $(cs +.u.mak, maz.out [-.u.mak maz.out])
  ?:  =('$' run)
    ?~  a=(mark-at more)  ~
    =/  three  (skip +.u.a)
    ?.  gap.three  ~
    ?~  b=(mark-at cs.three)  ~
    $(cs +.u.b, caz.out [[-.u.a -.u.b] caz.out])
  ?:  =('*' run)
    ?~  mak=(mark-at more)  ~
    =/  three  (skip +.u.mak)
    ?.  gap.three  ~
    ?~  pax=(knots cs.three)  ~
    $(cs +.u.pax, bar.out [[-.u.mak -.u.pax] bar.out])
  ::  /~, or anything else
  ::
  ~
::
::  +forward: .imp, gathered in reverse, in the header's order
::
++  forward
  |=  imp=imports
  ^-  imports
  :*  (flop sur.imp)  (flop lib.imp)  (flop raw.imp)
      (flop maz.imp)  (flop caz.imp)  (flop bar.imp)
  ==
::
::  +tauts: /- or /+ names: name, face=name or *name, separated by
::  commas
::
++  tauts
  |=  cs=tape
  ^-  (unit [(list @t) tape])
  =|  rev=(list @t)
  |-  ^-  (unit [(list @t) tape])
  =?  cs  &(?=(^ cs) =('*' i.cs))  t.cs
  ?~  got=(take cs sym 256)  ~
  =/  [nam=tape rest=tape]  u.got
  ?~  nam  ~
  =^  nam=tape  rest
    ?.  &(?=(^ rest) =('=' i.rest))  [nam rest]
    ?~  sec=(take t.rest sym 256)  [~ ~]
    u.sec
  ?~  nam  ~
  =.  rev  [(crip nam) rev]
  ?.  &(?=(^ rest) =(',' i.rest))  `[(flop rev) rest]
  $(cs cs:(skip t.rest))
::
::  +mark-at: a %mark
::
++  mark-at
  |=  cs=tape
  ^-  (unit [@t tape])
  ?.  &(?=(^ cs) =('%' i.cs))  ~
  ?~  got=(take t.cs sym 256)  ~
  ?~  -.u.got  ~
  `[(crip -.u.got) +.u.got]
::
::  +knots: a /path, of knots
::
++  knots
  |=  cs=tape
  ^-  (unit [path tape])
  ?.  &(?=(^ cs) =('/' i.cs))  ~
  =/  more=tape  t.cs
  =|  rev=path
  |-  ^-  (unit [path tape])
  ?~  got=(take more |=(c=@ |((sym c) =('.' c) =('_' c) =('~' c))) 256)  ~
  ?~  -.u.got  ~
  =.  rev  [(crip -.u.got) rev]
  =/  rest=tape  +.u.got
  ?.  &(?=(^ rest) =('/' i.rest))  `[(flop rev) rest]
  $(more t.rest)
::
::  +read-grad: what a mark file's +grad hands its diffs to: [~ ~] for a
::  core of its own, [~ ~ mark] for another mark, ~ if deskjam can't
::  tell
::
++  read-grad
  |=  tex=@t
  ^-  (unit (unit @t))
  =/  cs=tape  (trip (end [3 262.144] tex))
  ::  the first line that starts, after indentation, with ++  grad
  ::
  |-  ^-  (unit (unit @t))
  ?~  cs  ~
  =/  e=(unit @ud)  (find "\0a" `tape`cs)
  =/  lin=tape  ?~(e cs (scag u.e `tape`cs))
  =/  rest=tape  ?~(e ~ (slag +(u.e) `tape`cs))
  =/  bod=tape  (skip-spaces lin)
  ?.  =("++  grad" (scag 8 bod))  $(cs rest)
  =/  sep  (skip (weld (slag 8 bod) ['\0a' rest]))
  =*  val  cs.sep
  ?~  val  ~
  ?:  =('%' i.val)
    ?~  mak=(mark-at val)  ~
    ``-.u.mak
  ?:  |(=('|' i.val) =('^' i.val))  [~ ~]
  ~
::
++  skip-spaces
  |=  cs=tape
  ^-  tape
  ?~  cs  ~
  ?.  =(' ' i.cs)  cs
  $(cs t.cs)
::
::  +nest: the noun of a tuple, or a list if .lis, from its values in
::  reverse
::
++  nest
  |=  [rev=(list *) lis=?]
  ^-  *
  ?~  rev  ~
  =/  out=*  ?:(lis [i.rev ~] i.rev)
  =/  more=(list *)  t.rev
  |-  ^-  *
  ?~  more  out
  $(more t.more, out [i.more out])
--
