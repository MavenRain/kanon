(module
 (type $0 (struct (field (ref i31)) (field (ref eq))))
 (type $1 (func (result (ref eq))))
 (type $2 (func (param (ref eq)) (result (ref eq))))
 (type $3 (func (param (ref eq)) (result (ref i31))))
 (type $4 (func (result (ref i31))))
 (type $5 (func (result i32)))
 (export "main" (func $15))
 (func $0 (type $2) (param $0 (ref eq)) (result (ref eq))
  (local $1 (ref eq))
  (local $2 i32)
  (local $3 (ref eq))
  (local.set $1
   (local.get $0)
  )
  (local.set $2
   (block $block2 (result i32)
    (i31.get_u
     (struct.get $0 0
      (block $block1 (result (ref $0))
       (br $block2
        (i31.get_u
         (block $block (result (ref i31))
          (drop
           (br_on_cast $block1 (ref eq) (ref $0)
            (br_on_cast $block (ref eq) (ref i31)
             (local.get $1)
            )
           )
          )
          (unreachable)
         )
        )
       )
      )
     )
    )
   )
  )
  (if (result (ref eq))
   (i32.eq
    (local.get $2)
    (i32.const 0)
   )
   (then
    (ref.i31
     (i32.const 0)
    )
   )
   (else
    (if (result (ref eq))
     (i32.eq
      (local.get $2)
      (i32.const 1)
     )
     (then
      (local.set $3
       (struct.get $0 1
        (ref.cast (ref $0)
         (local.get $1)
        )
       )
      )
      (struct.new $0
       (ref.i31
        (i32.const 1)
       )
       (struct.new $0
        (ref.i31
         (i32.const 1)
        )
        (call $0
         (local.get $3)
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
 (func $1 (type $1) (result (ref eq))
  (struct.new $0
   (ref.i31
    (i32.const 1)
   )
   (ref.i31
    (i32.const 0)
   )
  )
 )
 (func $2 (type $1) (result (ref eq))
  (struct.new $0
   (ref.i31
    (i32.const 1)
   )
   (call $0
    (call $1)
   )
  )
 )
 (func $3 (type $1) (result (ref eq))
  (struct.new $0
   (ref.i31
    (i32.const 1)
   )
   (call $0
    (call $2)
   )
  )
 )
 (func $4 (type $1) (result (ref eq))
  (struct.new $0
   (ref.i31
    (i32.const 1)
   )
   (call $0
    (call $3)
   )
  )
 )
 (func $5 (type $1) (result (ref eq))
  (struct.new $0
   (ref.i31
    (i32.const 1)
   )
   (call $0
    (call $4)
   )
  )
 )
 (func $6 (type $1) (result (ref eq))
  (struct.new $0
   (ref.i31
    (i32.const 1)
   )
   (call $0
    (call $5)
   )
  )
 )
 (func $7 (type $1) (result (ref eq))
  (struct.new $0
   (ref.i31
    (i32.const 1)
   )
   (call $0
    (call $6)
   )
  )
 )
 (func $8 (type $1) (result (ref eq))
  (struct.new $0
   (ref.i31
    (i32.const 1)
   )
   (call $0
    (call $7)
   )
  )
 )
 (func $9 (type $1) (result (ref eq))
  (struct.new $0
   (ref.i31
    (i32.const 1)
   )
   (call $0
    (call $8)
   )
  )
 )
 (func $10 (type $1) (result (ref eq))
  (struct.new $0
   (ref.i31
    (i32.const 1)
   )
   (call $0
    (call $9)
   )
  )
 )
 (func $11 (type $1) (result (ref eq))
  (struct.new $0
   (ref.i31
    (i32.const 1)
   )
   (call $0
    (call $10)
   )
  )
 )
 (func $12 (type $1) (result (ref eq))
  (struct.new $0
   (ref.i31
    (i32.const 1)
   )
   (call $0
    (call $11)
   )
  )
 )
 (func $13 (type $3) (param $0 (ref eq)) (result (ref i31))
  (local $1 (ref eq))
  (local $2 i32)
  (local $3 (ref eq))
  (local $4 i32)
  (local.set $1
   (local.get $0)
  )
  (local.set $2
   (block $block2 (result i32)
    (i31.get_u
     (struct.get $0 0
      (block $block1 (result (ref $0))
       (br $block2
        (i31.get_u
         (block $block (result (ref i31))
          (drop
           (br_on_cast $block1 (ref eq) (ref $0)
            (br_on_cast $block (ref eq) (ref i31)
             (local.get $1)
            )
           )
          )
          (unreachable)
         )
        )
       )
      )
     )
    )
   )
  )
  (if (result (ref i31))
   (i32.eq
    (local.get $2)
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
      (local.get $2)
      (i32.const 1)
     )
     (then
      (local.set $3
       (struct.get $0 1
        (ref.cast (ref $0)
         (local.get $1)
        )
       )
      )
      (local.set $4
       (i32.add
        (i31.get_u
         (ref.cast (ref i31)
          (ref.i31
           (i32.const 1)
          )
         )
        )
        (i31.get_u
         (ref.cast (ref i31)
          (call $13
           (local.get $3)
          )
         )
        )
       )
      )
      (if
       (i32.gt_u
        (local.get $4)
        (i32.const 1073741823)
       )
       (then
        (unreachable)
       )
       (else
       )
      )
      (ref.i31
       (local.get $4)
      )
     )
     (else
      (unreachable)
     )
    )
   )
  )
 )
 (func $14 (type $4) (result (ref i31))
  (local $0 i32)
  (local.set $0
   (i32.add
    (i31.get_u
     (ref.cast (ref i31)
      (ref.i31
       (i32.const 0)
      )
     )
    )
    (i31.get_u
     (ref.cast (ref i31)
      (call $13
       (call $12)
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
 (func $15 (type $5) (result i32)
  (i31.get_s
   (call $14)
  )
 )
)
