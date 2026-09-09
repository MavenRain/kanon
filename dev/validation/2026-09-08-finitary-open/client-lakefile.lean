import Lake
open Lake DSL

package «kanon-open-client» where
  leanOptions := #[⟨`autoImplicit, false⟩]

require «kanon-meta» from "/Users/oobi/Documents/gpt4/kanon-open-terms/work/meta"

@[default_target]
lean_lib Client where
  roots := #[`Client]
