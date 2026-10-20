::  tests for /lib/deskjam-guard.hoon
::
::    run.sh puts this after the library, so its arms are in scope, and
::    gives it the desk's own /desk/bill, /sys/kelvin and /desk/docket-0
::    as cords. each check is a label and a ?>: a failing check crashes
::    the run, which then prints the labels of the checks up to it, the
::    failing one last. a run that gets through them all ends in
::    %tests-passed.
::
::  +spend and +bounded: count a noun's cells, shared subtrees each time
::  they occur, and give up when the gas runs out
::
~|  'spend: atoms have no cells'
?>  ?&  =(`10 (spend 10 ~))
        =(`0 (spend 0 5))
    ==
~|  'spend: one gas per cell'
?>  ?&  =(`9 (spend 10 [1 2]))
        =(`8 (spend 10 [1 2 3]))
        =(`0 (spend 2 [1 2 3]))
    ==
~|  'spend: running out'
?>  ?&  =(~ (spend 1 [1 2 3]))
        =(~ (spend 0 [1 2]))
    ==
~|  'bounded: small nouns with enough gas, and too little'
?>  ?&  (bounded 2 [1 2 3])
        !(bounded 1 [1 2 3])
        (bounded 0 0)
        (bounded 5 [[1 2] [3 4] 5])
        (bounded 4 [[1 2] [3 4] 5])
        !(bounded 3 [[1 2] [3 4] 5])
    ==
::  a jam bomb: 64 levels of b=[b b], a few bytes jammed, with 2^64 cells
::  as a tree
::
=/  bomb=*
  =|  [i=@ud b=*]
  |-  ^-  *
  ?:  =(64 i)  b
  $(i +(i), b [b b])
~|  'bounded: a shared dag counts as its tree, and fails fast'
?>  ?&  !(bounded 1.000.000 bomb)
        !(bounded 1.000.000 [%deskpack-0 %foo bomb])
        (lth (met 3 (jam bomb)) 1.000)
    ==
::  shared subtrees count each time they occur
::
=/  long=(list @)  (gulf 1 100.000)
~|  'bounded: a long list counts linearly'
?>  ?&  =(`0 (spend 100.000 long))
        (bounded 100.000 long)
        !(bounded 99.999 long)
        =(~ (spend 200.000 [long long]))
        =(`0 (spend 200.001 [long long]))
    ==
::  a deep noun doesn't exhaust the stack
::
=/  deep=*
  =|  [i=@ud n=*]
  |-  ^-  *
  ?:  =(100.000 i)  n
  $(i +(i), n [n 0])
~|  'bounded: a deeply nested noun'
?>  ?&  (bounded 100.000 deep)
        !(bounded 99.999 deep)
    ==
::
::  +read and +read-one: the values literal hoon spells out, read in one
::  pass without hoon's parser, or ~ for anything else
::
::    clay reads a desk's /desk/bill and /desk/docket-0 as one hoon
::    value each, and its /sys/kelvin as values separated by gaps. what
::    +read takes, it must read exactly as hoon does.
::
=/  hoon-one  |=(tex=@t `(unit *)``q:(slap !>(~) (ream tex)))
=/  hoon-all
  |=  tex=@t
  ^-  (unit (list *))
  `(turn (rash tex (star (ifix [gay gay] tall:vast))) |=(h=hoon q:(slap !>(~) h)))
=/  same  |=(tex=@t =((hoon-one tex) (read-one tex)))
~|  'read: the desk\'s own /desk/bill, as hoon reads it'
?>  &(?=(^ (read-one desk-bill)) (same desk-bill))
~|  'read: the desk\'s own /sys/kelvin, as hoon reads it'
?>  &(?=([~ ^] (read sys-kelvin)) =((hoon-all sys-kelvin) (read sys-kelvin)))
~|  'read: the desk\'s own /desk/docket-0, as hoon reads it'
?>  &(?=(^ (read-one desk-docket)) (same desk-docket))
~|  'read: atoms, as hoon reads them'
?>  ?&  (same '~')
        (same '%foo')
        (same '%foo-bar2')
        (same '\'a cord\'')
        (same '\'\'')
        (same '\'it\\\'s\'')
        (same '\'back\\\\slash\'')
        (same '\'a\\0ab\'')
        (same '408')
        (same '1.000')
        (same '0x9c.cfe7')
        (same '0v1.abcde')
        (same '~zod')
        (same '~sampel-palnet')
        (same '/')
        (same '/apps/deskjam')
    ==
~|  'read: cells and lists, as hoon reads them'
?>  ?&  (same '[%zuse 413]')
        (same '[0 2 1]')
        (same '[[1 2] 3]')
        (same '~[%a %b]')
        (same ':~  %a  %b  ==')
        (same ':~\0a  %a\0a  %b\0a==')
        (same ':~  %a  ::  a comment\0a    %b\0a==')
        (same 'title+\'Deskjam\'')
        (same 'version+[0 2 1]')
        (same 'site+/apps/deskjam')
        (same 'glob-http+[\'https://example.com/a.glob\' 0v1.abcde]')
        (same 'glob-ames+[~zod 0v0]')
        (same ':~  title+\'A\'  color+0xff.ffff  base+\'a\'  ==')
    ==
~|  'read: kelvins, separated by gaps'
?>  ?&  =((hoon-all '[%zuse 408]\0a[%zuse 409]\0a') (read '[%zuse 408]\0a[%zuse 409]\0a'))
        =((hoon-all '[%zuse 408]  [%zuse 409]') (read '[%zuse 408]  [%zuse 409]'))
        =((hoon-all '::  kernels\0a[%zuse 408]\0a') (read '::  kernels\0a[%zuse 408]\0a'))
    ==
~|  'read: literals real files don\'t use'
?>  ?&  =(~ (read-one '&'))
        =(~ (read-one '-1'))
        =(~ (read-one '~2026.10.20'))
        =(~ (read-one '.~~3.14'))
        =(~ (read-one ':-  1  2'))
        =(~ (read-one ':*  1  2  3  =='))
        =(~ (read-one '"a tape"'))
        =(~ (read-one '\'\'\'\0ablock\0a\'\'\''))
        =(~ (read-one '/apps/1'))
    ==
~|  'read: what hoon itself refuses'
?>  ?&  =(~ (read-one ':~  =='))
        =(~ (read-one ':~ %a =='))
        =(~ (read-one '[%a  %b]'))
        =(~ (read-one '\'unclosed'))
        =(~ (read-one '[%a %b'))
        =(~ (read-one '%a %b'))
    ==
~|  'read: loops, calls, scries and crashes'
?>  ?&  =(~ (read-one '=|  a=@  |-  $(a +(a))'))
        =(~ (read-one '|-  $'))
        =(~ (read-one '(add 1 2)'))
        =(~ (read-one '[1 (add 1 2)]'))
        =(~ (read-one ':~  %a  (add 1 2)  =='))
        =(~ (read-one 'title+(crip "x")'))
        =(~ (read-one '.^(* %cx /~zod/base/1/sys/kelvin)'))
        =(~ (read-one '!!'))
        =(~ (read-one 'a'))
        =(~ (read-one '`@t`5'))
    ==
::  hoon's parser takes exponential time on nesting that never closes,
::  and quadratic time on long literals; +read takes linear time, and
::  only a few levels of nesting
::
=/  rep  |=([n=@ud t=tape] ^-(tape (zing (reap n t))))
~|  'read: deep nesting is refused, at once'
?>  ?&  =(~ (read (crip (weld (rep 40 "~[") "0"))))
        =(~ (read (crip (weld (rep 40 ":~  ") "%a  =="))))
        =(~ (read (crip (weld (rep 40 "[") "0"))))
        =(~ (read (crip (weld (rep 40 "%+  ") "a"))))
        ?=(^ (read (crip :(weld (rep 8 "~[") "0" (rep 8 "]")))))
    ==
~|  'read: long literals and long lists, in linear time'
?>  ?&  ?=([~ [* ~]] (read (crip :(weld ":~  title+'" (rep 200.000 "a") "'  =="))))
        ?=([~ [* ~]] (read (crip :(weld ":~" (rep 30.000 "  %a") "  =="))))
        =(~ (read (crip :(weld "'" (rep 300.000 "a") "'"))))
    ==
::
::  +read-imports and +read-grad: a hoon file's ford imports, and what a
::  mark hands its diffs to, as clay's ford reads them
::
=/  head=@t
  %-  of-wain:format
  :~  '::  a comment'
      '/?  309'
      '/-  *foo, b=bar'
      '/+  baz,'
      '    qux-quux, w=webui-pages'
      '/=  f  /lib/x'
      '/%  m  %json'
      '/$  t  %json  %mime'
      '/*  i  %svg  /assets/icon/svg'
      '::'
      '|%'
      '--'
  ==
~|  'read-imports: every kind of import, faces and wildcards'
?>  .=  (read-imports head)
    :-  ~
    :*  sur=~['foo' 'bar']
        lib=~['baz' 'qux-quux' 'webui-pages']
        raw=~[/lib/x]
        maz=~['json']
        caz=~[['json' 'mime']]
        bar=~[['svg' /assets/icon/svg]]
    ==
~|  'read-imports: no imports'
?>  =(`*imports (read-imports '|%\0a++  a  1\0a--'))
~|  'read-imports: /~, which deskjam doesn\'t check'
?>  =(~ (read-imports '/~  d  *  /app\0a|%  --'))
~|  'read-imports: a rune without its gap starts the body, as clay reads it'
?>  =(`*imports (read-imports '/+ baz\0a|%  --'))
~|  'read-grad: another mark'
?>  =(``'noun' (read-grad '|_  a=@\0a++  grad  %noun\0a--'))
~|  'read-grad: a core of its own'
?>  =([~ ~] (read-grad '|_  a=@\0a++  grad\0a  |%\0a  ++  form  %txt-diff\0a  --\0a--'))
~|  'read-grad: none, or only in a comment'
?>  ?&  =(~ (read-grad '|_  a=@\0a++  grow  %noun\0a--'))
        =(~ (read-grad '::  ++  grad  %noun\0a|_  a=@\0a--'))
    ==
%tests-passed
