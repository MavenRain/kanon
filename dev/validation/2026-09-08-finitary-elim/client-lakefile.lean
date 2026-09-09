import Lake
open Lake DSL

package «kanon-elim-client» where
  leanOptions := #[⟨`autoImplicit, false⟩]

require «kanon-meta» from "../kanon-next/meta"

@[default_target]
lean_lib Client where
  roots := #[`Client]
