# Kanon coherence client

This independent Lean package checks dependent substitution and renaming coherence
through the public `KanonMeta` import. Its constructor specification and dependent
fibre are defined locally. The fibre retains a certified semantic observation and
an arbitrary annotation supplied at each variable.

The package uses the workspace `kanon-meta` dependency and its pinned toolchain.
Run `lake build` to check the library and regression target. Downstream projects
can reuse the fixture with `require «kanon-coherence-client» from "PATH"` and
`import KanonCoherenceClient`.
