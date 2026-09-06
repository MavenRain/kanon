(module
 (rec
  (type $0 (struct (field (ref i31)) (field (ref eq))))
  (type $1 (struct (field (ref i31)) (field (ref eq))))
 )
 (type $2 (struct (field (ref i31)) (field (ref eq))))
 (type $3 (func (param (ref eq)) (result (ref eq))))
 (type $4 (func (param (ref eq)) (result (ref i31))))
 (type $5 (func (result (ref i31))))
 (type $6 (func (result i32)))
 (export "main" (func $4))
 (func $0 (type $3) (param $0 (ref eq)) (result (ref eq))
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
      (struct.new $2
       (ref.i31
        (i32.const 1)
       )
       (call $1
        (local.get $3)
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
 (func $1 (type $3) (param $0 (ref eq)) (result (ref eq))
  (local $1 (ref eq))
  (local $2 i32)
  (local $3 (ref eq))
  (local.set $1
   (local.get $0)
  )
  (local.set $2
   (block $block2 (result i32)
    (i31.get_u
     (struct.get $1 0
      (block $block1 (result (ref $1))
       (br $block2
        (i31.get_u
         (block $block (result (ref i31))
          (drop
           (br_on_cast $block1 (ref eq) (ref $1)
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
    (local.set $3
     (struct.get $1 1
      (ref.cast (ref $1)
       (local.get $1)
      )
     )
    )
    (struct.new $2
     (ref.i31
      (i32.const 1)
     )
     (call $0
      (local.get $3)
     )
    )
   )
   (else
    (unreachable)
   )
  )
 )
 (func $2 (type $4) (param $0 (ref eq)) (result (ref i31))
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
     (struct.get $2 0
      (block $block1 (result (ref $2))
       (br $block2
        (i31.get_u
         (block $block (result (ref i31))
          (drop
           (br_on_cast $block1 (ref eq) (ref $2)
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
       (struct.get $2 1
        (ref.cast (ref $2)
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
          (call $2
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
 (func $3 (type $5) (result (ref i31))
  (return_call $2
   (call $0
    (struct.new $0
     (ref.i31
      (i32.const 1)
     )
     (struct.new $1
      (ref.i31
       (i32.const 0)
      )
      (struct.new $0
       (ref.i31
        (i32.const 1)
       )
       (struct.new $1
        (ref.i31
         (i32.const 0)
        )
        (ref.i31
         (i32.const 0)
        )
       )
      )
     )
    )
   )
  )
 )
 (func $4 (type $6) (result i32)
  (i31.get_s
   (call $3)
  )
 )
)
