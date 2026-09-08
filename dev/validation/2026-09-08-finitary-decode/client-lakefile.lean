import Lake
open Lake DSL

package «kanon-decode-client» where
  leanOptions := #[⟨`autoImplicit, false⟩]

require «kanon-meta» from "/Users/oobi/Documents/gpt2/kanon-continue/meta"

@[default_target]
lean_lib Client where
  roots := #[`Client]
