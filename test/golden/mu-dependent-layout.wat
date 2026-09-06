(module
 (type $0 (struct (field (ref i31)) (field (ref eq)) (field (ref eq))))
 (type $1 (func (result (ref eq))))
 (type $2 (func (param (ref i31)) (result (ref i31))))
 (type $3 (struct (field i32) (field (ref func)) (field (ref eq))))
 (type $4 (func (param (ref eq)) (result (ref i31))))
 (type $5 (func (result (ref i31))))
 (type $6 (func (param (ref eq) (ref eq)) (result (ref eq))))
 (type $7 (func (result i32)))
 (elem declare func $6)
 (export "main" (func $7))
 (func $0 (type $1) (result (ref eq))
  (struct.new $0
   (ref.i31
    (i32.const 0)
   )
   (ref.i31
    (i32.const 7)
   )
   (ref.i31
    (i32.const 8)
   )
  )
 )
 (func $1 (type $1) (result (ref eq))
  (struct.new $0
   (ref.i31
    (i32.const 0)
   )
   (ref.i31
    (i32.const 0)
   )
   (ref.i31
    (i32.const 9)
   )
  )
 )
 (func $2 (type $2) (param $0 (ref i31)) (result (ref i31))
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
 (func $3 (type $1) (result (ref eq))
  (struct.new $0
   (ref.i31
    (i32.const 0)
   )
   (struct.new $3
    (i32.const 1)
    (ref.func $6)
    (ref.i31
     (i32.const 0)
    )
   )
   (ref.i31
    (i32.const 10)
   )
  )
 )
 (func $4 (type $4) (param $0 (ref eq)) (result (ref i31))
  (local $1 (ref eq))
  (local $2 i32)
  (local $3 (ref eq))
  (local $4 (ref i31))
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
    (local.set $3
     (struct.get $0 1
      (ref.cast (ref $0)
       (local.get $1)
      )
     )
    )
    (local.set $4
     (ref.cast (ref i31)
      (struct.get $0 2
       (ref.cast (ref $0)
        (local.get $1)
       )
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
 (func $5 (type $5) (result (ref i31))
  (local $0 i32)
  (local $1 i32)
  (local.set $1
   (i32.add
    (i31.get_u
     (ref.cast (ref i31)
      (call $4
       (call $0)
      )
     )
    )
    (block (result i32)
     (local.set $0
      (i32.add
       (i31.get_u
        (ref.cast (ref i31)
         (call $4
          (call $1)
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
       (local.get $0)
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
        (local.get $0)
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
 (func $6 (type $6) (param $0 (ref eq)) (param $1 (ref eq)) (result (ref eq))
  (return_call $2
   (ref.cast (ref i31)
    (local.get $1)
   )
  )
 )
 (func $7 (type $7) (result i32)
  (i31.get_s
   (call $5)
  )
 )
)
