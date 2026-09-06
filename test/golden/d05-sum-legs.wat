(module
 (type $0 (struct (field (ref i31)) (field (ref eq))))
 (type $1 (func (result (ref eq))))
 (type $2 (func (param (ref eq)) (result (ref i31))))
 (type $3 (func (result (ref i31))))
 (type $4 (func (result i32)))
 (export "main" (func $6))
 (func $0 (type $1) (result (ref eq))
  (ref.i31
   (i32.const 0)
  )
 )
 (func $1 (type $1) (result (ref eq))
  (ref.i31
   (i32.const 1)
  )
 )
 (func $2 (type $1) (result (ref eq))
  (struct.new $0
   (ref.i31
    (i32.const 2)
   )
   (ref.i31
    (i32.const 5)
   )
  )
 )
 (func $3 (type $1) (result (ref eq))
  (struct.new $0
   (ref.i31
    (i32.const 3)
   )
   (ref.i31
    (i32.const 6)
   )
  )
 )
 (func $4 (type $2) (param $0 (ref eq)) (result (ref i31))
  (local $1 (ref eq))
  (local $2 i32)
  (local $3 (ref i31))
  (local $4 i32)
  (local $5 (ref i31))
  (local $6 i32)
  (local $7 i32)
  (local $8 i32)
  (local $scratch i32)
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
     (i32.const 1)
    )
   )
   (else
    (if (result (ref i31))
     (i32.eq
      (local.get $2)
      (i32.const 1)
     )
     (then
      (ref.i31
       (i32.const 2)
      )
     )
     (else
      (if (result (ref i31))
       (i32.eq
        (local.get $2)
        (i32.const 2)
       )
       (then
        (local.set $3
         (ref.cast (ref i31)
          (struct.get $0 1
           (ref.cast (ref $0)
            (local.get $1)
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
             (i32.const 10)
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
        (if (result (ref i31))
         (i32.eq
          (local.get $2)
          (i32.const 3)
         )
         (then
          (local.set $5
           (ref.cast (ref i31)
            (struct.get $0 1
             (ref.cast (ref $0)
              (local.get $1)
             )
            )
           )
          )
          (local.set $6
           (block (result i32)
            (local.set $scratch
             (i31.get_u
              (ref.cast (ref i31)
               (local.get $5)
              )
             )
            )
            (local.set $7
             (i31.get_u
              (ref.cast (ref i31)
               (ref.i31
                (i32.const 10)
               )
              )
             )
            )
            (local.get $scratch)
           )
          )
          (local.set $8
           (i32.mul
            (local.get $6)
            (local.get $7)
           )
          )
          (if
           (i32.ne
            (local.get $6)
            (i32.const 0)
           )
           (then
            (if
             (i32.ne
              (i32.div_u
               (local.get $8)
               (local.get $6)
              )
              (local.get $7)
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
            (local.get $8)
            (i32.const 1073741823)
           )
           (then
            (unreachable)
           )
           (else
           )
          )
          (ref.i31
           (local.get $8)
          )
         )
         (else
          (unreachable)
         )
        )
       )
      )
     )
    )
   )
  )
 )
 (func $5 (type $3) (result (ref i31))
  (local $0 i32)
  (local $1 i32)
  (local $2 i32)
  (local.set $0
   (i32.add
    (i31.get_u
     (ref.cast (ref i31)
      (call $4
       (call $0)
      )
     )
    )
    (i31.get_u
     (ref.cast (ref i31)
      (call $4
       (call $1)
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
  (local.set $2
   (i32.add
    (i31.get_u
     (ref.cast (ref i31)
      (ref.i31
       (local.get $0)
      )
     )
    )
    (block (result i32)
     (local.set $1
      (i32.add
       (i31.get_u
        (ref.cast (ref i31)
         (call $4
          (call $2)
         )
        )
       )
       (i31.get_u
        (ref.cast (ref i31)
         (call $4
          (call $3)
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
  (ref.i31
   (local.get $2)
  )
 )
 (func $6 (type $4) (result i32)
  (i31.get_s
   (call $5)
  )
 )
)
