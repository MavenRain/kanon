(module
 (type $0 (struct (field i32) (field (ref func)) (field (ref eq))))
 (type $1 (func (param (ref eq) (ref eq)) (result (ref eq))))
 (type $2 (struct (field (ref eq)) (field (ref eq))))
 (type $3 (func (param (ref eq) (ref eq) (ref eq)) (result (ref eq))))
 (type $4 (func (param (ref i31)) (result (ref i31))))
 (type $5 (func (param (ref i31) (ref i31)) (result (ref i31))))
 (type $6 (func (param (ref $0) (ref i31) (ref i31)) (result (ref i31))))
 (type $7 (func (result (ref i31))))
 (type $8 (func (result i32)))
 (elem declare func $5 $6 $8)
 (export "main" (func $9))
 (func $0 (type $5) (param $0 (ref i31)) (param $1 (ref i31)) (result (ref i31))
  (local $2 i32)
  (local $3 i32)
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
      (ref.i31
       (i32.const 3)
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
 (func $1 (type $6) (param $0 (ref $0)) (param $1 (ref i31)) (param $2 (ref i31)) (result (ref i31))
  (local $3 (ref $0))
  (local.set $3
   (ref.cast (ref $0)
    (call $7
     (local.get $0)
     (local.get $1)
    )
   )
  )
  (ref.cast (ref i31)
   (call_ref $1
    (struct.get $0 2
     (local.get $3)
    )
    (local.get $2)
    (ref.cast (ref $1)
     (struct.get $0 1
      (local.get $3)
     )
    )
   )
  )
 )
 (func $2 (type $4) (param $0 (ref i31)) (result (ref i31))
  (local $1 (ref $0))
  (local.set $1
   (ref.cast (ref $0)
    (call $7
     (struct.new $0
      (i32.const 2)
      (ref.func $5)
      (ref.i31
       (i32.const 0)
      )
     )
     (ref.i31
      (i32.const 4)
     )
    )
   )
  )
  (ref.cast (ref i31)
   (call_ref $1
    (struct.get $0 2
     (local.get $1)
    )
    (local.get $0)
    (ref.cast (ref $1)
     (struct.get $0 1
      (local.get $1)
     )
    )
   )
  )
 )
 (func $3 (type $4) (param $0 (ref i31)) (result (ref i31))
  (local $1 (ref $0))
  (local.set $1
   (ref.cast (ref $0)
    (call $7
     (struct.new $0
      (i32.const 2)
      (ref.func $6)
      (ref.i31
       (i32.const 0)
      )
     )
     (ref.i31
      (i32.const 1)
     )
    )
   )
  )
  (ref.cast (ref i31)
   (call_ref $1
    (struct.get $0 2
     (local.get $1)
    )
    (local.get $0)
    (ref.cast (ref $1)
     (struct.get $0 1
      (local.get $1)
     )
    )
   )
  )
 )
 (func $4 (type $7) (result (ref i31))
  (local $0 i32)
  (local $1 i32)
  (local.set $0
   (i32.add
    (i31.get_u
     (ref.cast (ref i31)
      (call $2
       (ref.i31
        (i32.const 5)
       )
      )
     )
    )
    (i31.get_u
     (ref.cast (ref i31)
      (call $3
       (ref.i31
        (i32.const 2)
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
  (local.set $1
   (i32.add
    (i31.get_u
     (ref.cast (ref i31)
      (ref.i31
       (local.get $0)
      )
     )
    )
    (i31.get_u
     (ref.cast (ref i31)
      (call $1
       (struct.new $0
        (i32.const 2)
        (ref.func $6)
        (ref.i31
         (i32.const 0)
        )
       )
       (ref.i31
        (i32.const 4)
       )
       (ref.i31
        (i32.const 6)
       )
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
 (func $5 (type $3) (param $0 (ref eq)) (param $1 (ref eq)) (param $2 (ref eq)) (result (ref eq))
  (return_call $0
   (ref.cast (ref i31)
    (local.get $1)
   )
   (ref.cast (ref i31)
    (local.get $2)
   )
  )
 )
 (func $6 (type $3) (param $0 (ref eq)) (param $1 (ref eq)) (param $2 (ref eq)) (result (ref eq))
  (local $3 i32)
  (local.set $3
   (i32.add
    (i31.get_u
     (ref.cast (ref i31)
      (local.get $1)
     )
    )
    (i31.get_u
     (ref.cast (ref i31)
      (local.get $2)
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
 (func $7 (type $1) (param $0 (ref eq)) (param $1 (ref eq)) (result (ref eq))
  (local $2 (ref $0))
  (local $3 i32)
  (local.set $2
   (ref.cast (ref $0)
    (local.get $0)
   )
  )
  (local.set $3
   (struct.get $0 0
    (local.get $2)
   )
  )
  (if (result (ref eq))
   (i32.eq
    (local.get $3)
    (i32.const 2)
   )
   (then
    (struct.new $0
     (i32.const 1)
     (ref.func $8)
     (struct.new $2
      (local.get $0)
      (local.get $1)
     )
    )
   )
   (else
    (if
     (i32.eq
      (local.get $3)
      (i32.const 1)
     )
     (then
      (return_call_ref $1
       (struct.get $0 2
        (local.get $2)
       )
       (local.get $1)
       (ref.cast (ref $1)
        (struct.get $0 1
         (local.get $2)
        )
       )
      )
     )
     (else
      (unreachable)
     )
    )
   )
  )
 )
 (func $8 (type $1) (param $0 (ref eq)) (param $1 (ref eq)) (result (ref eq))
  (local $2 (ref $2))
  (local $3 (ref $0))
  (local.set $2
   (ref.cast (ref $2)
    (local.get $0)
   )
  )
  (local.set $3
   (ref.cast (ref $0)
    (struct.get $2 0
     (local.get $2)
    )
   )
  )
  (return_call_ref $3
   (struct.get $0 2
    (local.get $3)
   )
   (struct.get $2 1
    (local.get $2)
   )
   (local.get $1)
   (ref.cast (ref $3)
    (struct.get $0 1
     (local.get $3)
    )
   )
  )
 )
 (func $9 (type $8) (result i32)
  (i31.get_s
   (call $4)
  )
 )
)
