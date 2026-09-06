(module
 (type $0 (func (param (ref i31) (ref i31)) (result (ref i31))))
 (type $1 (func (result (ref i31))))
 (type $2 (func (result i32)))
 (export "main" (func $4))
 (func $0 (type $0) (param $0 (ref i31)) (param $1 (ref i31)) (result (ref i31))
  (local $2 i32)
  (local.set $2
   (i32.add
    (i31.get_u
     (ref.cast (ref i31)
      (local.get $0)
     )
    )
    (i31.get_u
     (ref.cast (ref i31)
      (local.get $1)
     )
    )
   )
  )
  (if
   (i32.gt_u
    (local.get $2)
    (i32.const 1073741823)
   )
   (then
    (unreachable)
   )
   (else
   )
  )
  (ref.i31
   (local.get $2)
  )
 )
 (func $1 (type $0) (param $0 (ref i31)) (param $1 (ref i31)) (result (ref i31))
  (local $2 i32)
  (local.set $2
   (i32.add
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
  (if
   (i32.gt_u
    (local.get $2)
    (i32.const 1073741823)
   )
   (then
    (unreachable)
   )
   (else
   )
  )
  (return_call $0
   (ref.i31
    (local.get $2)
   )
   (local.get $1)
  )
 )
 (func $2 (type $0) (param $0 (ref i31)) (param $1 (ref i31)) (result (ref i31))
  (local $2 i32)
  (local.set $2
   (i32.add
    (i31.get_u
     (ref.cast (ref i31)
      (local.get $0)
     )
    )
    (i31.get_u
     (ref.cast (ref i31)
      (ref.i31
       (i32.const 2)
      )
     )
    )
   )
  )
  (if
   (i32.gt_u
    (local.get $2)
    (i32.const 1073741823)
   )
   (then
    (unreachable)
   )
   (else
   )
  )
  (return_call $1
   (ref.i31
    (local.get $2)
   )
   (local.get $1)
  )
 )
 (func $3 (type $1) (result (ref i31))
  (return_call $2
   (ref.i31
    (i32.const 3)
   )
   (ref.i31
    (i32.const 4)
   )
  )
 )
 (func $4 (type $2) (result i32)
  (i31.get_s
   (call $3)
  )
 )
)
