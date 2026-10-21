#import "../lib.typ": goldstone, diagram-signature, kallay-label

#set page(width: 190mm, height: auto, margin: 10mm)
#set text(size: 10pt)
#let panel(code, caption, ..options) = align(center)[
  #goldstone(code, labels: true, ..options)
  #linebreak()
  #caption
  #linebreak()
  #text(size: 8pt)[Signature: #repr(diagram-signature(code))]
]

= Similarity-transformed Hamiltonian and ECC diagrams

Signatures are (created particles, created holes, annihilated particles,
annihilated holes), all relative to the reference. Open operator legs are
short stubs: creation upward, annihilation downward. All arrows are shown
in the operator/ECC layout. $T$ uses solid lines and filled circles; $S$ uses
wavy lines and filled squares. Crossings without a marker are not contractions.

== Bare Hamiltonian: all thirteen vertices

#grid(columns: (1fr,) * 5, gutter: 5mm,
  ..range(13).map(eta => panel((eta,), [Vertex #eta], mode: "operator")),
)

== Partial contractions and scalar terms

#grid(columns: (1fr,) * 3, gutter: 6mm,
  panel("211 10", [Annihilation sector]),
  panel("211 0", [Unused creation legs], mode: "operator"),
  panel("242 10", [Correlation energy], mode: "operator"),
)

== ECC: incidence matters

#let base = ((2, 2, 1), (2, 2, 1), (0, 0, 0), (0, 0, 0), 10)
#let a = (base, (
  (1, ((0, 0), (1, 1), (0, 0))),
  (1, ((0, 0), (0, 0), (1, 1))),
))
#let b = (base, (
  (1, ((0, 0), (1, 0), (0, 1))),
  (1, ((0, 0), (0, 1), (1, 0))),
))
#let partial = ("211 5", ((2, ((1, 0), (0, 1))),))
#grid(columns: (1fr,) * 3, gutter: 6mm,
  panel(a, [Two single-source $S_1$ vertices]),
  panel(b, [Each $S_1$ touches two $T_2$ vertices]),
  panel(partial, [All three edge families; open $S$ legs]),
)

Both scalar graphs are valid in original ECC coordinates. Only the middle
graph meets the stronger doubly-linked energy rule. The renderer does not
filter diagrams or change amplitude coordinates.

== The S family is not restricted to four vertices

#let large-base = ((2, 1, 0), (2, 1, 0), (2, 1, 1), (2, 1, 1), 10)
#let rows = ()
#for (j, capacity) in ((2, 1), (2, 1), (1, 2), (1, 2)).enumerate() {
  for kind in range(2) {
    for _ in range(capacity.at(kind)) {
      let pairs = ((0, 0),) * 5
      pairs.at(j + 1).at(kind) = 1
      rows.push((1, pairs))
    }
  }
}
#panel((large-base, rows), [Four $T_2$ and twelve $S_1$ vertices], spacing: 9mm,
  level-gap: 8mm)
