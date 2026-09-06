(module
 (type $0 (func (param (ref eq)) (result (ref eq))))
 (type $1 (func (param (ref i31)) (result (ref i31))))
 (type $2 (func (result (ref i31))))
 (type $3 (func (result i32)))
 (export "main" (func $3))
 (func $0 (type $0) (param $0 (ref eq)) (result (ref eq))
  (local.get $0)
 )
 (func $1 (type $1) (param $0 (ref i31)) (result (ref i31))
  (ref.cast (ref i31)
   (call $0
    (local.get $0)
   )
  )
 )
 (func $2 (type $2) (result (ref i31))
  (local $0 i32)
  (local.set $0
   (i32.add
    (i31.get_u
     (ref.cast (ref i31)
      (call $0
       (ref.i31
        (i32.const 3)
       )
      )
     )
    )
    (i31.get_u
     (ref.cast (ref i31)
      (call $1
       (ref.i31
        (i32.const 4)
       )
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
 (func $3 (type $3) (result i32)
  (i31.get_s
   (call $2)
  )
 )
)
