import Lake
open Lake DSL

package «kanon-finitary-client» where
  leanOptions := #[⟨`autoImplicit, false⟩]

require «kanon-meta» from "/Users/oobi/Documents/gpt11/kanon/meta"

@[default_target]
lean_lib Client where
  roots := #[`Client]
