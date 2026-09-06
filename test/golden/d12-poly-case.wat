(module
 (type $0 (func (param (ref eq)) (result (ref eq))))
 (type $1 (func (result (ref i31))))
 (type $2 (func (result i32)))
 (export "main" (func $2))
 (func $0 (type $0) (param $0 (ref eq)) (result (ref eq))
  (local.get $0)
 )
 (func $1 (type $1) (result (ref i31))
  (local $0 (ref eq))
  (local $1 i32)
  (local.set $0
   (call $0
    (ref.i31
     (i32.eq
      (i31.get_u
       (ref.cast (ref i31)
        (ref.i31
         (i32.const 1)
        )
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
  )
  (local.set $1
   (block (result i32)
    (i31.get_u
     (block $block (result (ref i31))
      (drop
       (br_on_cast $block (ref eq) (ref i31)
        (local.get $0)
       )
      )
      (unreachable)
     )
    )
   )
  )
  (if (result (ref i31))
   (i32.eq
    (local.get $1)
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
      (local.get $1)
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
 (func $2 (type $2) (result i32)
  (i31.get_s
   (call $1)
  )
 )
)
