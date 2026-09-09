import Lake
open Lake DSL

package «kanon-base-change-client» where
  leanOptions := #[⟨`autoImplicit, false⟩]

require «kanon-meta» from "../../../../meta"

@[default_target]
lean_lib BaseChangeClient where
  roots := #[`BaseChangeClient]
