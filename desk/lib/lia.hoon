/+  runner-engine
=>  runner-engine
~%  %monad  +  ~
|%
++  script-lib
  =,  lia-sur
  =*  cw  coin-wasm:wasm-sur
  ~%  %core  +  ~
  |%
  ::
  +$  run-input
    (each (script-raw-form (list lia-value)) (list lia-value))
  ::
  ++  run-once
    =/  m  runnable
    |=  [sed=[module=octs =import] hint=term script=form:m]
    ^-  yield:m
    -:(run &+script (seed-init sed) hint)
  ::
  ++  run  ::  extend & extract
    ~/  %run
    |=  [input=run-input =seed hint=term]
    ::
    :: ~&  !.(call+!=(call))                 ::  [9 20 0 7]        pull
    :: ~&  !.(memread+!=(memread))           ::  [9 374 0 7]       pull
    :: ~&  !.(memwrite+!=(memwrite))         ::  [9 92 0 7]        pull
    :: ~&  !.(call-ext+!=(call-ext))         ::  [9 2986 0 7]      pull
    :: ~&  !.(try-m+!=(try:runnable))        ::  [9 21 9 372 0 7]  pull x2
    :: ~&  !.(catch-m+!=(catch:runnable))    ::  [9 4 9 372 0 7]   pull x2
    :: ~&  !.(return-m+!=(return:runnable))  ::  [9 20 9 372 0 7]  pull
    ::
    =,  engine-sur
    =/  m  runnable
    =>  [- [input=input seed=seed] +>]  ::  remove hint
    ^-  [yield:m _seed]
    =.  seed
      ?-    -.input
          %&
        seed(past ;<(,*:~ try:m past.seed p.input))  ::  past.seed >> p.input
      ::
          %|
        seed(shop (snoc shop.seed p.input))
      ==
    =/  ast  (main:parser module.seed)
    =/  valid  (validate-module:validator ast)
    ?>  ?=(%& -.valid)
    =/  sat=lia-state  [(conv:engine ast ~) shop.seed import.seed]
    |^  ^-  [yield:m _seed]
    :_  seed
    =<  -
    %.  sat
    ;<(* try:m init past.seed)  ::  init >> past.seed
    ::
    ++  init
      =/  m  (script ,~)
      ^-  form:m
      |=  sat=lia-state
      ^-  output:m
      =/  engine-res=result:engine
        (instantiate:engine p.sat)
      ?:  ?=(%0 -.engine-res)  [0+~ sat(p st.engine-res)]
      ?:  ?=(%2 -.engine-res)  [2+~ sat(p st.engine-res)]
      ::  engine-res = [%1 [[mod=cord name=cord] =request] module mem tables globals]
      ::
      ?>  ?=(%func -.request.engine-res)
      =/  sat-blocked=lia-state  [[~ +>.engine-res] q.sat r.sat]  ::  Wasm blocked on import
      =/  import-arrow
        (~(got by import.seed) mod.engine-res name.engine-res)
      =^  import-yil=(script-yield (list cw))  sat-blocked
        ((import-arrow args.request.engine-res) sat-blocked)
      ?.  ?=(%0 -.import-yil)  [import-yil sat-blocked]
      $(shop.p.sat (snoc shop.p.sat p.import-yil +.p.sat-blocked))
    --
  ::
  ::  Basic Lia ops (Kleisli arrows)
  ::
  ++  call
    |=  [name=cord args=(list @)]
    =/  m  (script (list @))
    ^-  form:m
    |=  sat=lia-state
    =,  module.p.sat
    =/  id=@  (find-func-id:engine name module.p.sat)
    =/  id-local=@
      (sub id (lent funcs.import-section))
    =/  =func-type
      (snag type-id:(snag id-local function-section) type-section)
    ?>  =((lent params.func-type) (lent args))
    =/  engine-res=result:engine
      (invoke:engine name (types-atoms-to-coins params.func-type args) p.sat)
    ?:  ?=(%0 -.engine-res)
      [0+(turn out.engine-res cw-to-atom) sat(p st.engine-res)]
    ?:  ?=(%2 -.engine-res)
      [2+~ sat(p st.engine-res)]
    ::  engine-res = [%1 [[mod=cord name=cord] =request] module mem tables globals]
    ::
    ?>  ?=(%func -.request.engine-res)
    =/  sat-blocked=lia-state  [[~ +>.engine-res] q.sat r.sat]  ::  Wasm blocked on import
    =/  import-arrow
      (~(got by r.sat) mod.engine-res name.engine-res)
    =^  import-yil=(script-yield (list cw))  sat-blocked
      ((import-arrow args.request.engine-res) sat-blocked)
    ?.  ?=(%0 -.import-yil)  [import-yil sat-blocked]
    $(shop.p.sat (snoc shop.p.sat p.import-yil +.p.sat-blocked))
  ::
  ++  call-1
    |=  [name=cord args=(list @)]
    =/  m  (script @)
    ^-  form:m
    ;<  out=(list @)  try:m  (call name args)
    ?>  =(1 (lent out))
    (return:m -.out)
  ::
  ++  memread
    |=  [ptr=@ len=@]
    =/  m  (script octs)
    ^-  form:m
    |=  sat=lia-state
    ?~  mem.p.sat  [2+~ sat]
    =,  u.mem.p.sat
    ?:  (gth (add ptr len) (mul n-pages page-size))
      [2+~ sat]
    [0+[len (cut 3 [ptr len] buffer)] sat]
  ::
  ++  memwrite
    |=  [ptr=@ len=@ src=@]
    =/  m  (script ,~)
    ^-  form:m
    |=  sat=lia-state
    ?~  mem.p.sat  [2+~ sat]
    =,  u.mem.p.sat
    ?:  (gth (add ptr len) (mul n-pages page-size))
      [2+~ sat]
    :-  0+~
    sat(buffer.u.mem.p (sew 3 [ptr len src] buffer))
  ::
  ++  call-ext
    |=  [name=term args=(list lia-value)]
    =/  m  (script (list lia-value))
    ^-  form:m
    |=  sat=lia-state
    ?~  q.sat
      [1+[name args] sat]
    [0+i.q.sat sat(q t.q.sat)]
  ::
  ::  misc
  ::
  ++  runnable  (script (list lia-value))
  ++  seed-init
    |=  [module=octs =import]
    ^-  seed
    =/  m  (script (list lia-value))
    :*  module
        (return:m ~)
        ~
        import
    ==
  ++  cw-to-atom
    |=  cw=coin-wasm:wasm-sur
    ^-  @
    ?<  ?=(%ref -.cw)
    +.cw
  ::
  ++  types-atoms-to-coins
    |=  [a=(list valtype:wasm-sur) b=(list @)]
    ^-  (list coin-wasm:wasm-sur)
    ?:  &(?=(~ a) ?=(~ b))  ~
    ?>  &(?=(^ a) ?=(^ b))
    :_  $(a t.a, b t.b)
    ?<  ?=(ref-type:wasm-sur i.a)
    ^-  cw
    ?-  i.a
      %i32   [i.a i.b]
      %i64   [i.a i.b]
      %f32   [i.a i.b]
      %f64   [i.a i.b]
      %v128  [i.a i.b]
    ==
  ::
  ++  page-size  ^~((bex 16))
  ::
  ++  yield-need
    |*  a=(script-yield)
    ?>  ?=(%0 -.a)
    p.a
  ::
  --  ::  |script-lib
--