import Lake
open Lake DSL

package «kanon-subst-client» where
  leanOptions := #[⟨`autoImplicit, false⟩]

require «kanon-meta» from "../kanon-next/meta"

@[default_target]
lean_lib Client where
  roots := #[`Client]
