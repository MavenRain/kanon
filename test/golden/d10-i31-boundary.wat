(module
 (type $0 (func (result (ref i31))))
 (type $1 (func (result i32)))
 (export "main" (func $1))
 (func $0 (type $0) (result (ref i31))
  (local $0 i32)
  (local.set $0
   (i32.add
    (i31.get_u
     (ref.cast (ref i31)
      (ref.i31
       (i32.const 1073741823)
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
  (if
   (i32.gt_u
    (local.get $0)
    (i32.const 1073741823)
   )
   (then
    (unreachable)
   )
   (else
   )
  )
  (ref.i31
   (local.get $0)
  )
 )
 (func $1 (type $1) (result i32)
  (i31.get_s
   (call $0)
  )
 )
)
