(module
 (type $0 (struct (field (ref eq)) (field (ref eq))))
 (type $1 (struct (field i32) (field (ref func)) (field (ref eq))))
 (type $2 (struct (field (ref eq))))
 (type $3 (func (param (ref eq) (ref eq)) (result (ref eq))))
 (type $4 (func (param (ref eq)) (result (ref eq))))
 (type $5 (func (param (ref i31) (ref i31)) (result (ref i31))))
 (type $6 (func (param (ref i31)) (result (ref $0))))
 (type $7 (func (result (ref i31))))
 (type $8 (func (result i32)))
 (elem declare func $4)
 (export "main" (func $5))
 (func $0 (type $4) (param $0 (ref eq)) (result (ref eq))
  (local.get $0)
 )
 (func $1 (type $5) (param $0 (ref i31)) (param $1 (ref i31)) (result (ref i31))
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
 (func $2 (type $6) (param $0 (ref i31)) (result (ref $0))
  (local $1 (ref eq))
  (local.set $1
   (call $0
    (local.get $0)
   )
  )
  (struct.new $0
   (struct.new $1
    (i32.const 1)
    (ref.func $4)
    (struct.new $2
     (ref.cast (ref i31)
      (local.get $1)
     )
    )
   )
   (ref.cast (ref i31)
    (local.get $1)
   )
  )
 )
 (func $3 (type $7) (result (ref i31))
  (local $0 (ref $0))
  (local $1 (ref $1))
  (local $2 (ref i31))
  (local $3 (ref $1))
  (local.set $0
   (call $2
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
 (func $4 (type $3) (param $0 (ref eq)) (param $1 (ref eq)) (result (ref eq))
  (return_call $1
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
 (func $5 (type $8) (result i32)
  (i31.get_s
   (call $3)
  )
 )
)
