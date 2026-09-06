(module
 (type $0 (struct (field (ref eq)) (field (ref eq))))
 (type $1 (struct (field (ref i31)) (field (ref eq))))
 (type $2 (func (result (ref i31))))
 (type $3 (struct (field i32) (field (ref func)) (field (ref eq))))
 (type $4 (func (param (ref eq)) (result (ref eq))))
 (type $5 (func (param (ref eq) (ref eq)) (result (ref eq))))
 (type $6 (func (param (ref eq)) (result (ref $0))))
 (type $7 (func (param (ref $0)) (result (ref eq))))
 (type $8 (func (param (ref i31)) (result (ref i31))))
 (type $9 (func (result i32)))
 (elem declare func $12)
 (export "main" (func $13))
 (func $0 (type $4) (param $0 (ref eq)) (result (ref eq))
  (local.get $0)
 )
 (func $1 (type $6) (param $0 (ref eq)) (result (ref $0))
  (struct.new $0
   (local.get $0)
   (local.get $0)
  )
 )
 (func $2 (type $7) (param $0 (ref $0)) (result (ref eq))
  (local $1 (ref $0))
  (local $2 (ref eq))
  (local $3 (ref eq))
  (local.set $1
   (local.get $0)
  )
  (local.set $2
   (struct.get $0 0
    (local.get $1)
   )
  )
  (local.set $3
   (struct.get $0 1
    (local.get $1)
   )
  )
  (local.get $2)
 )
 (func $3 (type $6) (param $0 (ref eq)) (result (ref $0))
  (struct.new $0
   (local.get $0)
   (local.get $0)
  )
 )
 (func $4 (type $4) (param $0 (ref eq)) (result (ref eq))
  (struct.new $1
   (ref.i31
    (i32.const 1)
   )
   (local.get $0)
  )
 )
 (func $5 (type $4) (param $0 (ref eq)) (result (ref eq))
  (local $1 (ref eq))
  (local $2 i32)
  (local $3 (ref eq))
  (local $4 (ref eq))
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
    (local.get $3)
   )
   (else
    (if (result (ref eq))
     (i32.eq
      (local.get $2)
      (i32.const 1)
     )
     (then
      (local.set $4
       (struct.get $1 1
        (ref.cast (ref $1)
         (local.get $1)
        )
       )
      )
      (local.get $4)
     )
     (else
      (unreachable)
     )
    )
   )
  )
 )
 (func $6 (type $2) (result (ref i31))
  (drop
   (ref.i31
    (i32.const 0)
   )
  )
  (unreachable)
 )
 (func $7 (type $2) (result (ref i31))
  (local $0 (ref eq))
  (local $1 i32)
  (local $2 (ref i31))
  (local $3 (ref i31))
  (local $4 i32)
  (local.set $0
   (call $0
    (call $4
     (ref.i31
      (i32.const 7)
     )
    )
   )
  )
  (local.set $1
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
             (local.get $0)
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
    (local.get $1)
    (i32.const 0)
   )
   (then
    (local.set $2
     (ref.cast (ref i31)
      (struct.get $1 1
       (ref.cast (ref $1)
        (local.get $0)
       )
      )
     )
    )
    (local.get $2)
   )
   (else
    (if (result (ref i31))
     (i32.eq
      (local.get $1)
      (i32.const 1)
     )
     (then
      (local.set $3
       (ref.cast (ref i31)
        (struct.get $1 1
         (ref.cast (ref $1)
          (local.get $0)
         )
        )
       )
      )
      (local.set $4
       (i32.add
        (i31.get_u
         (ref.cast (ref i31)
          (local.get $3)
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
 (func $8 (type $2) (result (ref i31))
  (local $0 (ref $0))
  (local $1 (ref $0))
  (local $2 (ref $0))
  (local $3 (ref $0))
  (local $4 (ref i31))
  (local $5 (ref i31))
  (local.set $0
   (call $1
    (call $1
     (ref.i31
      (i32.const 5)
     )
    )
   )
  )
  (local.set $1
   (ref.cast (ref $0)
    (struct.get $0 0
     (local.get $0)
    )
   )
  )
  (local.set $2
   (ref.cast (ref $0)
    (struct.get $0 1
     (local.get $0)
    )
   )
  )
  (local.set $3
   (local.get $1)
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
  (local.get $5)
 )
 (func $9 (type $8) (param $0 (ref i31)) (result (ref i31))
  (local $1 i32)
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
 (func $10 (type $2) (result (ref i31))
  (local $0 (ref $3))
  (local.set $0
   (ref.cast (ref $3)
    (struct.get $0 0
     (call $3
      (struct.new $3
       (i32.const 1)
       (ref.func $12)
       (ref.i31
        (i32.const 0)
       )
      )
     )
    )
   )
  )
  (ref.cast (ref i31)
   (call_ref $5
    (struct.get $3 2
     (local.get $0)
    )
    (ref.i31
     (i32.const 8)
    )
    (ref.cast (ref $5)
     (struct.get $3 1
      (local.get $0)
     )
    )
   )
  )
 )
 (func $11 (type $2) (result (ref i31))
  (local $0 i32)
  (local $1 i32)
  (local $2 i32)
  (local $3 i32)
  (local $4 i32)
  (local.set $0
   (i32.add
    (i31.get_u
     (ref.cast (ref i31)
      (call $2
       (struct.new $0
        (ref.i31
         (i32.const 3)
        )
        (ref.i31
         (i32.const 4)
        )
       )
      )
     )
    )
    (i31.get_u
     (ref.cast (ref i31)
      (ref.cast (ref i31)
       (struct.get $0 1
        (call $3
         (ref.i31
          (i32.const 9)
         )
        )
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
  (local.set $4
   (i32.add
    (i31.get_u
     (ref.cast (ref i31)
      (ref.i31
       (local.get $0)
      )
     )
    )
    (block (result i32)
     (local.set $3
      (i32.add
       (i31.get_u
        (ref.cast (ref i31)
         (call $5
          (struct.new $1
           (ref.i31
            (i32.const 0)
           )
           (ref.i31
            (i32.const 2)
           )
          )
         )
        )
       )
       (block (result i32)
        (local.set $2
         (i32.add
          (i31.get_u
           (ref.cast (ref i31)
            (call $7)
           )
          )
          (block (result i32)
           (local.set $1
            (i32.add
             (i31.get_u
              (ref.cast (ref i31)
               (call $8)
              )
             )
             (i31.get_u
              (ref.cast (ref i31)
               (call $10)
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
           (i31.get_u
            (ref.cast (ref i31)
             (ref.i31
              (local.get $1)
             )
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
        (i31.get_u
         (ref.cast (ref i31)
          (ref.i31
           (local.get $2)
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
     (i31.get_u
      (ref.cast (ref i31)
       (ref.i31
        (local.get $3)
       )
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
 (func $12 (type $5) (param $0 (ref eq)) (param $1 (ref eq)) (result (ref eq))
  (return_call $9
   (ref.cast (ref i31)
    (local.get $1)
   )
  )
 )
 (func $13 (type $9) (result i32)
  (i31.get_s
   (call $11)
  )
 )
)
