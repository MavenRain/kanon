import Lake
open Lake DSL

package «kanon-coherence-client» where
  leanOptions := #[⟨`autoImplicit, false⟩]

require «kanon-meta» from "/Users/oobi/Documents/gpt1/kanon-coherence/meta"

@[default_target]
lean_lib KanonCoherenceClient where
  roots := #[`KanonCoherenceClient]

@[default_target]
lean_lib CoherenceTests where
  roots := #[`test.Coherence]
