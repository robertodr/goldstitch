# ccdiagrams

A Typst module and Python generator for antisymmetrized Goldstone diagrams of CC equations, similarity-transformed Hamiltonians, and extended coupled cluster (ECC). Diagrams are specified with the compact integer notation of Kállay and Surján and rendered with [Fletcher](https://typst.app/universe/package/fletcher/).

```typ
#import "lib.typ": goldstone, kallay-label

#goldstone("220 000 000 000 4")
#kallay-label("220 000 000 000 4")
#goldstone("111 220 7")
#goldstone("111 111 220 10")
#goldstone("220 222 10")
```

See [`examples/basic.typ`](examples/basic.typ) for the resulting four diagrams.

## Kállay notation

A diagram is a tuple of four amplitude triplets followed by an interaction-vertex number:

```text
((ε₀, ι₀, π₀), (ε₁, ι₁, π₁), (ε₂, ι₂, π₂), (ε₃, ι₃, π₃), η)
```

For example, `kallay-label("220 4")` renders `((2, 2, 0), (0, 0, 0), (0, 0, 0), (0, 0, 0), 4)`.

For each cluster-amplitude vertex `Tᵢ`:

1. `εᵢ` is its excitation level;
2. `ιᵢ` is the total number of internal lines contracted with the Hamiltonian;
3. `πᵢ` is the number of those internal lines that are outgoing particle lines.

Before adding any S vertices, `Tᵢ` has `ιᵢ − πᵢ` internal hole lines, `εᵢ − πᵢ` external particle lines, and `εᵢ − ιᵢ + πᵢ` external hole lines. The final integer `η` selects one of the 13 one- and two-electron Hamiltonian vertices in Fig. 1 of the paper:

| ID | Matrix element | Internal particles | Internal holes |
|---:|:---------------|-------------------:|---------------:|
| 0 | `f_ab` | 1 | 0 |
| 1 | `f_ji` | 0 | 1 |
| 2 | `f_ia` | 1 | 1 |
| 3 | `<ad‖bc>` | 2 | 0 |
| 4 | `<jk‖il>` | 0 | 2 |
| 5 | `<ja‖ib>` | 1 | 1 |
| 6 | `<ic‖ab>` | 2 | 1 |
| 7 | `<ij‖ak>` | 1 | 2 |
| 8 | `<ac‖ib>` | 1 | 0 |
| 9 | `<aj‖ik>` | 0 | 1 |
| 10 | `<ij‖ab>` | 2 | 2 |
| 11 | `f_ai` | 0 | 0 |
| 12 | `<ab‖ij>` | 0 | 0 |

These counts give the lower annihilation capacities in Fig. 1, not all orbital indices of the matrix element. Equation diagrams use all these capacities; operator diagrams may leave some uncontracted. Vertices 11 and 12 are bare contributions and can be written simply as `"11"` and `"12"`.

All fields must be non-negative integers, and `η` must be between 0 and 12. Amplitude triplets are ordered lexicographically: excitation levels are nondecreasing; equal excitation levels have nondecreasing internal-line counts; and equal excitation levels and internal-line counts have nondecreasing internal particle-line counts.

Trailing `000` amplitudes can be omitted, so `"220 4"` and `"220 000 000 000 4"` are equivalent.

For fields greater than nine, delimit a triplet with `/`, `:`, or `,`:

```typ
#goldstone("10/1/1 0")
```

Structured input is also accepted:

```typ
#goldstone(((2, 2, 0), (0, 0, 0), 4))
```

`goldstone` checks that amplitude ranks and line counts are valid and do not exceed the selected interaction's particle/hole capacities. Use `mode: "equation"` to require complete contraction of the Hamiltonian annihilation lines.

## Styling

```typ
#goldstone(
  "220 4",
  spacing: 7.5mm,
  level-gap: 4.5mm,
  stroke: 0.65pt,
  mark-scale: 100%,
  arrows: "minimal",
  leg-angle: 20deg,
  loop-bend: 75deg,
  t1-bar-extension: 2.5pt,
  labels: false,
  debug: false,
)
```

**Equation layout.** Particles point out of a `T` vertex and holes point into it. At every vertex one fermion line arrives and one leaves, so the drawn segments join into continuous fermion lines: open paths that begin and end outside the diagram, and closed loops. By default, `arrows: "minimal"` places one arrow on a straight fermion segment attached to the Hamiltonian vertex, never on a bent particle–hole loop. It prefers a straight Hamiltonian–cluster contraction over any external segment, then prefers particles over holes and longer segments over shorter ones. If there is no straight contraction, it falls back to a straight external Hamiltonian leg. `"all"` marks every segment. Filled black dots mark every fermion attachment to a cluster bar; open circles mark the fermionic endpoints of the dashed Hamiltonian vertex. The validated tuple order is canonical rather than spatial: cluster vertices are initially grouped by their Hamiltonian attachments, with mirrored tie-breaking for symmetric halves. The layout then compares whole-bar orders to minimize crossings between the dashed interaction and open cluster legs, keeping distinct Hamiltonian endpoints and retaining the initial order on ties. Upper-only Hamiltonian endpoints also switch sides when this avoids an open-leg crossing. Hamiltonian endpoints are centered over their actual attachment sites, keeping closed particle–hole lenses vertical and shared contractions balanced. Shared lower endpoints are nudged away from open legs when needed for clearance, preferably outward to retain space between Hamiltonian endpoints, without changing contraction sides or moving closed lenses. Fully open hole–particle pairs sharing a cluster attachment site are grouped at the left or right end of the bar. In multi-cluster diagrams they face toward the nearest outside edge of the whole cluster row, rather than into the gaps between bars; for a lone or centered bar, the side that shortens contractions is chosen. This rule does not apply to singly open legs: the relative order of contracted sites and existing particle–hole pairings is preserved. The single-`T_1` realization of interaction 5 uses its equivalent split layout, with an upper V at one end of the interaction line and the lower particle–hole pair at the other. Contractions of one species are initially matched to cluster vertices by a minimal-displacement, order-preserving assignment, then attachment sites are reordered to keep fully open pairs outside. Topology-required crossings are retained. Each solid horizontal bar is a cluster amplitude, with one particle–hole pair meeting the bar for every excitation rank. Bars end at their outermost vertices for ranks above one; `T_1` bars extend by `t1-bar-extension` on either side of their sole vertex. `leg-angle` controls the preferred opening angle at a cluster vertex; the default produces the steep symmetric 80°–20°–80° geometry. `loop-bend` sets the opening of the lens drawn between a particle and a hole line that contract the same cluster vertex with the same Hamiltonian vertex. Through-lines continue straight across the Hamiltonian endpoint, with the contracted and free legs forming a symmetric V at the cluster vertex. Set `labels: true` to show `T` ranks and the interaction serial number.

## Operator and ECC rendering

The same `goldstone` function accepts partial-contraction tuples and nested
ECC tuples, without converting either to projected equation diagrams:

```typ
#import "lib.typ": goldstone, diagram-signature

#goldstone("10")       // Bare two-body annihilation vertex
#goldstone("211 10")   // One T2; some H annihilators remain external
#assert(diagram-signature("211 10") == (1, 2, 1, 2))

#let ecc = ("221 221 10", (
  (1, ((0, 0), (1, 0), (0, 1))),
  (1, ((0, 0), (0, 1), (1, 0))),
))
#goldstone(ecc, labels: true)
#assert(diagram-signature(ecc) == (0, 0, 0, 0))
```

ECC input is `(base, rows)`, where each row is
`(rank, ((p_H, h_H), (p_T1, h_T1), ...))`. The base accepts any Kállay form
above, including compact strings. A dictionary `(base: ..., rows: ...)` is
also accepted. Columns refer to H followed by **active** T vertices, not the
four padded slots. S rows have no padding or four-vertex limit. The renderer
preserves their supplied order and incidence, checking connectivity, row
rank bounds, and cumulative source capacities. `parse-diagram` returns the
validated model; `diagram-signature` returns the four external quasiparticle
counts. `kallay-label` also accepts partially contracted base tuples.

Layout selection:

- `mode: "auto"` (default): preserves the existing equation layout when there
  are no S vertices and all H annihilation lines are contracted; otherwise
  uses the layered operator/ECC layout.
- `mode: "operator"`: forces the layered layout, including for scalar and
  pure-creation sectors.
- `mode: "ecc"`: requires nested ECC input and uses the layered layout.
- `mode: "equation"`: retains strict equation validation and the old layout.

The layered layout puts T below H and S above H. When both cluster families
are present, H moves to the side so T–S edges do not pass through unrelated
Hamiltonian vertices. Creation legs are short upward stubs; annihilation
legs are short downward stubs. They do not share a projection boundary.
Particle arrows run from creation to annihilation endpoints; hole arrows
run oppositely. Coincident opposite-species contractions form curved lenses.
Crossings without a dot are **not** vertices. Both cluster families use solid
bars with one filled fermionic site per rank, and H retains its dashed line
and open sites. Dense diagrams can still have crossings.

Styling options above also apply here; the layered defaults are
`arrows: "all"` and `mark-scale: 85%`. Use `labels: true` for T/S ranks and H's
vertex number. For canonical-coordinate energy graphs, you can additionally
set `excitation-symbol: $Sigma$` to label the excitation bars accordingly.
This changes labels only: rendering neither filters diagrams nor performs an
amplitude-coordinate transformation.

See [`examples/operators.typ`](examples/operators.typ) and its
[PDF](examples/operators.pdf) for all thirteen bare vertices, partial
contractions, inequivalent ECC scalar graphs, and a twelve-S-vertex example.

## Generating tuples

`generate_kallay.py` is the single generator for all constructions (the former
`generate_ecc.py` has been merged into it; import ECC functions from
`generate_kallay` now). By default it generates every connected CC tuple for a truncation level,
grouped by equation rank (including the correlation-energy equation, `k = 0`).
The scalar reference energy is excluded; truncation level zero returns `{0: []}`.

```sh
python3 generate_kallay.py 2
python3 generate_kallay.py 3 --equation 2 --json
```

It can also be imported:

```py
from generate_kallay import generate_diagrams, generate_equation

ccsd = generate_diagrams(2)       # {0: [...], 1: [...], 2: [...]}
doubles = generate_equation(2, 2)
```

Every returned diagram contains four amplitude triplets, with trailing
`(0, 0, 0)` padding, followed by the Hamiltonian vertex number.

### Full similarity-transformed Hamiltonian

The Python API also generates every expanded connected antisymmetrized
operator topology of `exp(-T) H_N exp(T)`, including external annihilation
lines. It uses the same tuple format: the remaining Hamiltonian lines are
inferred from `η` and the contracted-line counts.

```py
from generate_kallay import (
    generate_equation,
    generate_similarity_transformed,
    count_similarity_transformed,
    external_signature,
)

hbar = generate_similarity_transformed(2)
assert len(hbar) == count_similarity_transformed(2) == 183
# Signature order: created particles, created holes,
#                  annihilated particles, annihilated holes (quasiparticles).
doubles = [d for d in hbar if external_signature(d) == (2, 2, 0, 0)]
assert doubles == generate_equation(2, 2)
```

For `n >= 1`, the total is
`(n**4 + 18*n**3 + 87*n**2 + 106*n + 12) // 4`.
At `n = 0` it is 13: all bare one- and two-body Hamiltonian vertices.
The generated correlation-energy scalar is included; the reference energy
is excluded. Counts are for unfactorized topologies before imposing the CC
residual equations, not labelled Wick contractions or numerical operations.

Generate these operator tuples from the CLI with
`python3 generate_kallay.py 2 --mode hbar --json`. The JSON output is an array
of diagrams, directly usable with Typst's `json()` and `goldstone`.
See [`diagram-count-derivation.typ`](diagram-count-derivation.typ) and its
[PDF](diagram-count-derivation.pdf) for the construction algorithm,
sector-resolved generating function, and proofs of both counting formulas.

### Extended coupled cluster

The same [`generate_kallay.py`](generate_kallay.py) extends the construction to
`exp(S) exp(-T) H_N exp(T) exp(-S)`, with the **same truncation rank `n`**
for pure excitation `T` and pure deexcitation `S`. Both retain all ranks
`1..n`; their amplitudes remain independent, so this does not mean `S=T†`:

```py
from generate_kallay import (
    generate_ecc,
    generate_ecc_energy,
    ecc_external_signature,
)

operator = generate_ecc(n=1)
assert len(operator) == 395
assert sum(ecc_external_signature(d) == (0, 0, 0, 0) for d in operator) == 20
assert len(generate_ecc_energy(2)) == 1503
```

Each ECC tuple is `(base, s_rows)`. `base` is the ordinary padded
Hamiltonian–T tuple; each S row is `(rank, ((p_H, h_H), (p_T1, h_T1), ...))`,
with columns for H and each **active** T vertex. Its incidence entries,
not just row totals, are needed to identify the graph. S rows are unpadded.
Canonicalization quotients row permutations and simultaneous permutations
of columns belonging to identical base T triplets. The crude four-slot bound
is 24 permutations, but the Hamiltonian's particle/hole capacities leave
at most **four admissible permutations**.

**Connectivity distinction:** in the literal operator every T must touch H,
and every S must touch H or at least one T. The stronger rule that each S
must touch H or **two distinct T vertices** applies to the energy in
*reparameterized canonical ECC amplitude coordinates*. Request that separate
energy construction with `generate_ecc_energy(2, canonical_coordinates=True)`
(907 topologies). It is not the energy of the unchanged input amplitudes with
some terms arbitrarily discarded.

The coordinate map leaves `S` unchanged and defines a new excitation operator
`Σ` by `Σ|Φ₀⟩ = Q exp(S) T|Φ₀⟩`, where `Q` removes the reference component.
Its inverse is `T|Φ₀⟩ = Q exp(-S) Σ|Φ₀⟩`. At singles–doubles truncation,
`Σ₂=T₂` and `Σ₁=T₁+(S₁T₂)_{exc,1}`. The latter contraction absorbs the
single-source S–T attachments that disappear from the canonical energy
expansion. Both maps only lower excitation rank, so they preserve the common
rank-complete space `1..n`. The two formulations therefore have identical
energies at **mapped amplitudes** and corresponding stationary solutions,
despite their different diagram counts. “Canonical” here refers to canonical
conjugate amplitudes in the time-dependent bivariational equations—not to
Hartree–Fock orbitals or graph sorting. Additional selected-amplitude
restrictions require a separate check of closure under the coordinate map.

This is a small-truncation reference enumerator. The full `n=2` operator
has **8,743,171** topologies by independent Burnside coefficient counting;
constructing its entire tuple list is expensive. Energy-only generation
prunes annihilation sectors and enforces complete S contractions early.
See the manuscript's ECC section for constraints, a uniqueness proof,
termination bounds, and the orbit-counting method. Tests independently
implement that count without listing graph representatives. The renderer
supports both operator and scalar ECC tuples; the generator does not compute
their algebraic weights.

### CLI modes and JSON-to-Typst workflow

```sh
# Original equation CLI and JSON rank-object format are unchanged:
python3 generate_kallay.py 2 --equation 1 --json

# All other modes return a JSON array:
python3 generate_kallay.py 2 --mode hbar --json > hbar.json
python3 generate_kallay.py 1 --mode ecc --json > ecc.json
python3 generate_kallay.py 2 --mode ecc-energy --json > energy.json
python3 generate_kallay.py 2 --mode ecc-energy --canonical-coordinates --json > canonical-energy.json
```

`--equation` is valid only in equation mode; `--canonical-coordinates` is
valid only with `--mode ecc-energy`. Without `--json`, each mode prints a
comment header followed by one Python tuple per line. Full ECC enumeration
at `n=2` already has millions of diagrams; prefer energy-only generation
when appropriate.

After generating `ecc.json`, place this Typst source beside it and `lib.typ`:

```typ
#import "lib.typ": goldstone
#set page(width: auto, height: auto)
#let diagrams = json("ecc.json")
#grid(columns: 4, gutter: 4mm,
  ..diagrams.slice(0, calc.min(24, diagrams.len())).map(d => goldstone(d)),
)
```

For equation JSON, select a rank first, e.g. `json("equations.json").at("2")`.
No tuple conversion or orbital labels are needed.

Run the generator and Typst regression tests with (Typst tests require `typst` on `PATH`):

```sh
python3 -m unittest discover -s tests -v
```

## Reference

M. Kállay and P. R. Surján, “Higher excitations in coupled-cluster theory,” *J. Chem. Phys.* **115**, 2945–2954 (2001), [doi:10.1063/1.1383290](https://doi.org/10.1063/1.1383290), especially Eq. (8) and Fig. 1.
