(module
 (type $0 (func (result (ref i31))))
 (type $1 (func (param (ref eq)) (result (ref i31))))
 (type $2 (func (result i32)))
 (export "main" (func $4))
 (func $0 (type $1) (param $0 (ref eq)) (result (ref i31))
  (local $1 (ref eq))
  (local $2 i32)
  (local.set $1
   (local.get $0)
  )
  (local.set $2
   (block (result i32)
    (i31.get_u
     (block $block (result (ref i31))
      (drop
       (br_on_cast $block (ref eq) (ref i31)
        (local.get $1)
       )
      )
      (unreachable)
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
      (ref.i31
       (i32.const 1)
      )
     )
     (else
      (unreachable)
     )
    )
   )
  )
 )
 (func $1 (type $0) (result (ref i31))
  (local $0 i32)
  (local $1 i32)
  (local $2 i32)
  (local $3 i32)
  (local $4 i32)
  (local $5 i32)
  (local $scratch i32)
  (local $scratch_7 i32)
  (local.set $0
   (i32.add
    (i31.get_u
     (ref.cast (ref i31)
      (ref.i31
       (i32.const 2)
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
    (local.get $0)
    (i32.const 1073741823)
   )
   (then
    (unreachable)
   )
   (else
   )
  )
  (local.set $3
   (block (result i32)
    (local.set $scratch_7
     (i31.get_u
      (ref.cast (ref i31)
       (ref.i31
        (local.get $0)
       )
      )
     )
    )
    (local.set $1
     (block (result i32)
      (local.set $scratch
       (i31.get_u
        (ref.cast (ref i31)
         (ref.i31
          (i32.const 7)
         )
        )
       )
      )
      (local.set $2
       (i31.get_u
        (ref.cast (ref i31)
         (ref.i31
          (i32.const 4)
         )
        )
       )
      )
      (local.get $scratch)
     )
    )
    (local.set $4
     (i31.get_u
      (ref.cast (ref i31)
       (ref.i31
        (if (result i32)
         (i32.lt_u
          (local.get $1)
          (local.get $2)
         )
         (then
          (i32.const 0)
         )
         (else
          (i32.sub
           (local.get $1)
           (local.get $2)
          )
         )
        )
       )
      )
     )
    )
    (local.get $scratch_7)
   )
  )
  (local.set $5
   (i32.mul
    (local.get $3)
    (local.get $4)
   )
  )
  (if
   (i32.ne
    (local.get $3)
    (i32.const 0)
   )
   (then
    (if
     (i32.ne
      (i32.div_u
       (local.get $5)
       (local.get $3)
      )
      (local.get $4)
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
 (func $2 (type $0) (result (ref i31))
  (local $0 i32)
  (local.set $0
   (i32.add
    (i31.get_u
     (ref.cast (ref i31)
      (call $0
       (ref.i31
        (i32.eq
         (i31.get_u
          (ref.cast (ref i31)
           (ref.i31
            (i32.const 4)
           )
          )
         )
         (i31.get_u
          (ref.cast (ref i31)
           (ref.i31
            (i32.const 4)
           )
          )
         )
        )
       )
      )
     )
    )
    (i31.get_u
     (ref.cast (ref i31)
      (call $0
       (ref.i31
        (i32.lt_u
         (i31.get_u
          (ref.cast (ref i31)
           (ref.i31
            (i32.const 1)
           )
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
 (func $3 (type $0) (result (ref i31))
  (local $0 i32)
  (local.set $0
   (i32.add
    (i31.get_u
     (ref.cast (ref i31)
      (call $1)
     )
    )
    (i31.get_u
     (ref.cast (ref i31)
      (call $2)
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
 (func $4 (type $2) (result i32)
  (i31.get_s
   (call $3)
  )
 )
)
