/-  *deskjam
/+  dg=deskjam-guard
=,  mimes:html
|_  dp=deskpack
++  grow
  |%
  ++  noun      dp
  ++  deskjam   jam
  ++  jam       (^jam [%deskpack-0 dp])
  ++  mime      :-  /application/octet-stream
                (as-octs:mimes:html jam)
  --
++  grab
  |%
  ++  noun     deskpack
  ++  deskjam  jam
  ::
  ::    a crafted file can unpack to a noun whose tree is exponentially
  ::    larger than the file, which the molds below would take as long
  ::    to walk. a real deskjam has far fewer cells than the file has bits.
  ::
  ++  jam
    |=  mud=@
    =/  non  (cue mud)
    ?.  (bounded:dg (budget:dg (met 0 mud)) non)
      ~|(%deskjam-too-big !!)
    =/  =(cask)  ;;((cask) non)
    ?+  p.cask  ~|([%unknown-deskjam-mark mark=p.cask] !!)
      %deskpack-0  ;;(deskpack q.cask)
    ==
  ++  mime  |=(mim=^mime (jam q.q.mim))
  --
++  grad  %noun
--
