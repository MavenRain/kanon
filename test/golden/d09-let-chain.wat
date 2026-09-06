(module
 (type $0 (struct (field (ref i31)) (field (ref eq))))
 (type $1 (func (param (ref eq)) (result (ref i31))))
 (type $2 (func (result (ref i31))))
 (type $3 (func (result i32)))
 (export "main" (func $2))
 (func $0 (type $1) (param $0 (ref eq)) (result (ref i31))
  (local $1 (ref i31))
  (local $2 (ref eq))
  (local $3 i32)
  (local $4 (ref i31))
  (local $5 i32)
  (local $6 (ref i31))
  (local $7 i32)
  (local $8 i32)
  (local $9 i32)
  (local $10 (ref i31))
  (local $11 i32)
  (local $12 (ref i31))
  (local $13 i32)
  (local $scratch i32)
  (local.set $1
   (ref.i31
    (i32.const 10)
   )
  )
  (local.set $2
   (local.get $0)
  )
  (local.set $3
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
             (local.get $2)
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
  (local.set $10
   (if (result (ref i31))
    (i32.eq
     (local.get $3)
     (i32.const 0)
    )
    (then
     (local.set $4
      (ref.cast (ref i31)
       (struct.get $0 1
        (ref.cast (ref $0)
         (local.get $2)
        )
       )
      )
     )
     (local.set $5
      (i32.add
       (i31.get_u
        (ref.cast (ref i31)
         (local.get $4)
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
       (local.get $5)
       (i32.const 1073741823)
      )
      (then
       (unreachable)
      )
      (else
      )
     )
     (ref.i31
      (local.get $5)
     )
    )
    (else
     (if (result (ref i31))
      (i32.eq
       (local.get $3)
       (i32.const 1)
      )
      (then
       (local.set $6
        (ref.cast (ref i31)
         (struct.get $0 1
          (ref.cast (ref $0)
           (local.get $2)
          )
         )
        )
       )
       (local.set $7
        (block (result i32)
         (local.set $scratch
          (i31.get_u
           (ref.cast (ref i31)
            (local.get $6)
           )
          )
         )
         (local.set $8
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
       (local.set $9
        (i32.mul
         (local.get $7)
         (local.get $8)
        )
       )
       (if
        (i32.ne
         (local.get $7)
         (i32.const 0)
        )
        (then
         (if
          (i32.ne
           (i32.div_u
            (local.get $9)
            (local.get $7)
           )
           (local.get $8)
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
         (local.get $9)
         (i32.const 1073741823)
        )
        (then
         (unreachable)
        )
        (else
        )
       )
       (ref.i31
        (local.get $9)
       )
      )
      (else
       (unreachable)
      )
     )
    )
   )
  )
  (local.set $11
   (i32.add
    (i31.get_u
     (ref.cast (ref i31)
      (local.get $1)
     )
    )
    (i31.get_u
     (ref.cast (ref i31)
      (local.get $10)
     )
    )
   )
  )
  (if
   (i32.gt_u
    (local.get $11)
    (i32.const 1073741823)
   )
   (then
    (unreachable)
   )
   (else
   )
  )
  (local.set $12
   (ref.i31
    (local.get $11)
   )
  )
  (local.set $13
   (i32.add
    (i31.get_u
     (ref.cast (ref i31)
      (local.get $12)
     )
    )
    (i31.get_u
     (ref.cast (ref i31)
      (ref.i31
       (i32.const 100)
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
  (ref.i31
   (local.get $13)
  )
 )
 (func $1 (type $2) (result (ref i31))
  (local $0 i32)
  (local.set $0
   (i32.add
    (i31.get_u
     (ref.cast (ref i31)
      (call $0
       (struct.new $0
        (ref.i31
         (i32.const 0)
        )
        (ref.i31
         (i32.const 3)
        )
       )
      )
     )
    )
    (i31.get_u
     (ref.cast (ref i31)
      (call $0
       (struct.new $0
        (ref.i31
         (i32.const 1)
        )
        (ref.i31
         (i32.const 4)
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
  (ref.i31
   (local.get $0)
  )
 )
 (func $2 (type $3) (result i32)
  (i31.get_s
   (call $1)
  )
 )
)
