(module
 (type $0 (struct (field (ref eq)) (field (ref eq)) (field (ref eq))))
 (type $1 (func (result (ref $0))))
 (type $2 (func (result (ref i31))))
 (type $3 (func (result i32)))
 (export "main" (func $2))
 (func $0 (type $1) (result (ref $0))
  (struct.new $0
   (ref.i31
    (i32.const 2)
   )
   (ref.i31
    (i32.const 3)
   )
   (ref.i31
    (i32.const 4)
   )
  )
 )
 (func $1 (type $2) (result (ref i31))
  (local $0 i32)
  (local $1 i32)
  (local $2 i32)
  (local $3 i32)
  (local $scratch i32)
  (local.set $0
   (block (result i32)
    (local.set $scratch
     (i31.get_u
      (ref.cast (ref i31)
       (ref.cast (ref i31)
        (struct.get $0 0
         (call $0)
        )
       )
      )
     )
    )
    (local.set $1
     (i31.get_u
      (ref.cast (ref i31)
       (ref.cast (ref i31)
        (struct.get $0 1
         (call $0)
        )
       )
      )
     )
    )
    (local.get $scratch)
   )
  )
  (local.set $2
   (i32.mul
    (local.get $0)
    (local.get $1)
   )
  )
  (if
   (i32.ne
    (local.get $0)
    (i32.const 0)
   )
   (then
    (if
     (i32.ne
      (i32.div_u
       (local.get $2)
       (local.get $0)
      )
      (local.get $1)
     )
     (then
      (unreachable)
     )
     (else
     )
    )
   )
   (else
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
  (local.set $3
   (i32.add
    (i31.get_u
     (ref.cast (ref i31)
      (ref.i31
       (local.get $2)
      )
     )
    )
    (i31.get_u
     (ref.cast (ref i31)
      (ref.cast (ref i31)
       (struct.get $0 2
        (call $0)
       )
      )
     )
    )
   )
  )
  (if
   (i32.gt_u
    (local.get $3)
    (i32.const 1073741823)
   )
   (then
    (unreachable)
   )
   (else
   )
  )
  (ref.i31
   (local.get $3)
  )
 )
 (func $2 (type $3) (result i32)
  (i31.get_s
   (call $1)
  )
 )
)
