import Lake
open Lake DSL

package «kanon-fusion-client» where
  leanOptions := #[⟨`autoImplicit, false⟩]

require «kanon-meta» from "../../../../meta"

@[default_target]
lean_lib FusionClient where
  roots := #[`FusionClient]
