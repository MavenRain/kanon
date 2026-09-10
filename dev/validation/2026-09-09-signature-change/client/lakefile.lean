import Lake
open Lake DSL

package signatureChangeClient where
  leanOptions := #[⟨`autoImplicit, false⟩]

require «kanon-meta» from "../../../../meta"

@[default_target]
lean_lib SignatureChangeClient where
  roots := #[`SignatureChangeClient]
