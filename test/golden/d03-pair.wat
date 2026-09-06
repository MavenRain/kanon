(module
 (type $0 (struct (field (ref eq)) (field (ref eq))))
 (type $1 (func (result (ref $0))))
 (type $2 (func (param (ref i31)) (result (ref $0))))
 (type $3 (func (result (ref i31))))
 (type $4 (func (result i32)))
 (export "main" (func $4))
 (func $0 (type $1) (result (ref $0))
  (struct.new $0
   (ref.i31
    (i32.const 11)
   )
   (ref.i31
    (i32.const 6)
   )
  )
 )
 (func $1 (type $2) (param $0 (ref i31)) (result (ref $0))
  (local $1 i32)
  (struct.new $0
   (local.get $0)
   (block (result (ref i31))
    (local.set $1
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
      (local.get $1)
      (i32.const 1073741823)
     )
     (then
      (unreachable)
     )
     (else
     )
    )
    (ref.i31
     (local.get $1)
    )
   )
  )
 )
 (func $2 (type $1) (result (ref $0))
  (return_call $1
   (ref.i31
    (i32.const 4)
   )
  )
 )
 (func $3 (type $3) (result (ref i31))
  (local $0 (ref $0))
  (local $1 (ref i31))
  (local $2 (ref i31))
  (local $3 (ref $0))
  (local $4 (ref i31))
  (local $5 (ref i31))
  (local $6 i32)
  (local $7 (ref $0))
  (local $8 (ref i31))
  (local $9 (ref i31))
  (local $10 (ref $0))
  (local $11 (ref i31))
  (local $12 (ref i31))
  (local $13 i32)
  (local $14 i32)
  (local.set $0
   (call $0)
  )
  (local.set $1
   (ref.cast (ref i31)
    (struct.get $0 0
     (local.get $0)
    )
   )
  )
  (local.set $2
   (ref.cast (ref i31)
    (struct.get $0 1
     (local.get $0)
    )
   )
  )
  (local.set $6
   (i32.add
    (i31.get_u
     (ref.cast (ref i31)
      (local.get $1)
     )
    )
    (block (result i32)
     (local.set $3
      (call $0)
     )
     (local.set $4
      (ref.cast (ref i31)
       (struct.get $0 0
        (local.get $3)
       )
      )
     )
     (local.set $5
      (ref.cast (ref i31)
       (struct.get $0 1
        (local.get $3)
       )
      )
     )
     (i31.get_u
      (ref.cast (ref i31)
       (local.get $5)
      )
     )
    )
   )
  )
  (if
   (i32.gt_u
    (local.get $6)
    (i32.const 1073741823)
   )
   (then
    (unreachable)
   )
   (else
   )
  )
  (local.set $14
   (i32.add
    (i31.get_u
     (ref.cast (ref i31)
      (ref.i31
       (local.get $6)
      )
     )
    )
    (block (result i32)
     (local.set $7
      (call $2)
     )
     (local.set $8
      (ref.cast (ref i31)
       (struct.get $0 0
        (local.get $7)
       )
      )
     )
     (local.set $9
      (ref.cast (ref i31)
       (struct.get $0 1
        (local.get $7)
       )
      )
     )
     (local.set $13
      (i32.add
       (i31.get_u
        (ref.cast (ref i31)
         (local.get $8)
        )
       )
       (block (result i32)
        (local.set $10
         (call $2)
        )
        (local.set $11
         (ref.cast (ref i31)
          (struct.get $0 0
           (local.get $10)
          )
         )
        )
        (local.set $12
         (ref.cast (ref i31)
          (struct.get $0 1
           (local.get $10)
          )
         )
        )
        (i31.get_u
         (ref.cast (ref i31)
          (local.get $12)
         )
        )
       )
      )
     )
     (if
      (i32.gt_u
       (local.get $13)
       (i32.const 1073741823)
      )
      (then
       (unreachable)
      )
      (else
      )
     )
     (i31.get_u
      (ref.cast (ref i31)
       (ref.i31
        (local.get $13)
       )
      )
     )
    )
   )
  )
  (if
   (i32.gt_u
    (local.get $14)
    (i32.const 1073741823)
   )
   (then
    (unreachable)
   )
   (else
   )
  )
  (ref.i31
   (local.get $14)
  )
 )
 (func $4 (type $4) (result i32)
  (i31.get_s
   (call $3)
  )
 )
)
