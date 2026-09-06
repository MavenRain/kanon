(module
 (type $0 (struct (field i32) (field (ref func)) (field (ref eq))))
 (type $1 (func (param (ref eq) (ref eq)) (result (ref eq))))
 (type $2 (func (param (ref $0)) (result (ref i31))))
 (type $3 (func (param (ref i31)) (result (ref eq))))
 (type $4 (func (result (ref i31))))
 (type $5 (func (result i32)))
 (elem declare func $3)
 (export "main" (func $4))
 (func $0 (type $2) (param $0 (ref $0)) (result (ref i31))
  (local $1 (ref $0))
  (local $2 (ref eq))
  (local $3 i32)
  (local.set $1
   (local.get $0)
  )
  (local.set $2
   (call_ref $1
    (struct.get $0 2
     (local.get $1)
    )
    (ref.i31
     (i32.const 1)
    )
    (ref.cast (ref $1)
     (struct.get $0 1
      (local.get $1)
     )
    )
   )
  )
  (local.set $3
   (block (result i32)
    (i31.get_u
     (block $block (result (ref i31))
      (drop
       (br_on_cast $block (ref eq) (ref i31)
        (local.get $2)
       )
      )
      (unreachable)
     )
    )
   )
  )
  (if (result (ref i31))
   (i32.eq
    (local.get $3)
    (i32.const 0)
   )
   (then
    (ref.i31
     (i32.const 0)
    )
   )
   (else
    (if (result (ref i31))
     (i32.eq
      (local.get $3)
      (i32.const 1)
     )
     (then
      (ref.i31
       (i32.const 1)
      )
     )
     (else
      (unreachable)
     )
    )
   )
  )
 )
 (func $1 (type $3) (param $0 (ref i31)) (result (ref eq))
  (ref.i31
   (i32.eq
    (i31.get_u
     (ref.cast (ref i31)
      (local.get $0)
     )
    )
    (i31.get_u
     (ref.cast (ref i31)
      (ref.i31
       (i32.const 1)
      )
     )
    )
   )
  )
 )
 (func $2 (type $4) (result (ref i31))
  (return_call $0
   (struct.new $0
    (i32.const 1)
    (ref.func $3)
    (ref.i31
     (i32.const 0)
    )
   )
  )
 )
 (func $3 (type $1) (param $0 (ref eq)) (param $1 (ref eq)) (result (ref eq))
  (return_call $1
   (ref.cast (ref i31)
    (local.get $1)
   )
  )
 )
 (func $4 (type $5) (result i32)
  (i31.get_s
   (call $2)
  )
 )
)
