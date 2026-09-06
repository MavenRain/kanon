(module
 (type $0 (struct (field (ref eq)) (field (ref eq))))
 (type $1 (struct (field i32) (field (ref func)) (field (ref eq))))
 (type $2 (struct (field (ref eq))))
 (type $3 (func (param (ref eq) (ref eq)) (result (ref eq))))
 (type $4 (func (param (ref i31) (ref i31)) (result (ref i31))))
 (type $5 (func (param (ref i31)) (result (ref $0))))
 (type $6 (func (result (ref i31))))
 (type $7 (func (result i32)))
 (elem declare func $5 $6)
 (export "main" (func $7))
 (func $0 (type $4) (param $0 (ref i31)) (param $1 (ref i31)) (result (ref i31))
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
 (func $1 (type $5) (param $0 (ref i31)) (result (ref $0))
  (local $1 i32)
  (local $2 i32)
  (local $3 i32)
  (local $scratch i32)
  (struct.new $0
   (struct.new $1
    (i32.const 1)
    (ref.func $5)
    (struct.new $2
     (local.get $0)
    )
   )
   (block (result (ref i31))
    (local.set $1
     (block (result i32)
      (local.set $scratch
       (i31.get_u
        (ref.cast (ref i31)
         (local.get $0)
        )
       )
      )
      (local.set $2
       (i31.get_u
        (ref.cast (ref i31)
         (ref.i31
          (i32.const 2)
         )
        )
       )
      )
      (local.get $scratch)
     )
    )
    (local.set $3
     (i32.mul
      (local.get $1)
      (local.get $2)
     )
    )
    (if
     (i32.ne
      (local.get $1)
      (i32.const 0)
     )
     (then
      (if
       (i32.ne
        (i32.div_u
         (local.get $3)
         (local.get $1)
        )
        (local.get $2)
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
  )
 )
 (func $2 (type $4) (param $0 (ref i31)) (param $1 (ref i31)) (result (ref i31))
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
 (func $3 (type $5) (param $0 (ref i31)) (result (ref $0))
  (local $1 i32)
  (local $2 (ref i31))
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
  (local.set $2
   (ref.i31
    (local.get $1)
   )
  )
  (struct.new $0
   (struct.new $1
    (i32.const 1)
    (ref.func $6)
    (struct.new $2
     (local.get $2)
    )
   )
   (local.get $2)
  )
 )
 (func $4 (type $6) (result (ref i31))
  (local $0 (ref $0))
  (local $1 (ref $1))
  (local $2 (ref i31))
  (local $3 (ref $1))
  (local $4 (ref $0))
  (local $5 (ref $1))
  (local $6 (ref i31))
  (local $7 i32)
  (local $8 (ref $0))
  (local $9 (ref $1))
  (local $10 (ref i31))
  (local $11 (ref $1))
  (local $12 (ref $0))
  (local $13 (ref $1))
  (local $14 (ref i31))
  (local $15 i32)
  (local $16 i32)
  (local.set $0
   (call $1
    (ref.i31
     (i32.const 5)
    )
   )
  )
  (local.set $1
   (ref.cast (ref $1)
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
  (local.set $3
   (local.get $1)
  )
  (local.set $7
   (i32.add
    (i31.get_u
     (ref.cast (ref i31)
      (call_ref $3
       (struct.get $1 2
        (local.get $3)
       )
       (ref.i31
        (i32.const 6)
       )
       (ref.cast (ref $3)
        (struct.get $1 1
         (local.get $3)
        )
       )
      )
     )
    )
    (block (result i32)
     (local.set $4
      (call $1
       (ref.i31
        (i32.const 5)
       )
      )
     )
     (local.set $5
      (ref.cast (ref $1)
       (struct.get $0 0
        (local.get $4)
       )
      )
     )
     (local.set $6
      (ref.cast (ref i31)
       (struct.get $0 1
        (local.get $4)
       )
      )
     )
     (i31.get_u
      (ref.cast (ref i31)
       (local.get $6)
      )
     )
    )
   )
  )
  (if
   (i32.gt_u
    (local.get $7)
    (i32.const 1073741823)
   )
   (then
    (unreachable)
   )
   (else
   )
  )
  (local.set $16
   (i32.add
    (i31.get_u
     (ref.cast (ref i31)
      (ref.i31
       (local.get $7)
      )
     )
    )
    (block (result i32)
     (local.set $8
      (call $3
       (ref.i31
        (i32.const 2)
       )
      )
     )
     (local.set $9
      (ref.cast (ref $1)
       (struct.get $0 0
        (local.get $8)
       )
      )
     )
     (local.set $10
      (ref.cast (ref i31)
       (struct.get $0 1
        (local.get $8)
       )
      )
     )
     (local.set $11
      (local.get $9)
     )
     (local.set $15
      (i32.add
       (i31.get_u
        (ref.cast (ref i31)
         (call_ref $3
          (struct.get $1 2
           (local.get $11)
          )
          (ref.i31
           (i32.const 4)
          )
          (ref.cast (ref $3)
           (struct.get $1 1
            (local.get $11)
           )
          )
         )
        )
       )
       (block (result i32)
        (local.set $12
         (call $3
          (ref.i31
           (i32.const 2)
          )
         )
        )
        (local.set $13
         (ref.cast (ref $1)
          (struct.get $0 0
           (local.get $12)
          )
         )
        )
        (local.set $14
         (ref.cast (ref i31)
          (struct.get $0 1
           (local.get $12)
          )
         )
        )
        (i31.get_u
         (ref.cast (ref i31)
          (local.get $14)
         )
        )
       )
      )
     )
     (if
      (i32.gt_u
       (local.get $15)
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
        (local.get $15)
       )
      )
     )
    )
   )
  )
  (if
   (i32.gt_u
    (local.get $16)
    (i32.const 1073741823)
   )
   (then
    (unreachable)
   )
   (else
   )
  )
  (ref.i31
   (local.get $16)
  )
 )
 (func $5 (type $3) (param $0 (ref eq)) (param $1 (ref eq)) (result (ref eq))
  (return_call $0
   (ref.cast (ref i31)
    (struct.get $2 0
     (ref.cast (ref $2)
      (local.get $0)
     )
    )
   )
   (ref.cast (ref i31)
    (local.get $1)
   )
  )
 )
 (func $6 (type $3) (param $0 (ref eq)) (param $1 (ref eq)) (result (ref eq))
  (return_call $2
   (ref.cast (ref i31)
    (struct.get $2 0
     (ref.cast (ref $2)
      (local.get $0)
     )
    )
   )
   (ref.cast (ref i31)
    (local.get $1)
   )
  )
 )
 (func $7 (type $7) (result i32)
  (i31.get_s
   (call $4)
  )
 )
)
