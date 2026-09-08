# ccdiagrams

A **Typst drawing library** for antisymmetrized Goldstone diagrams of CC equations, similarity-transformed Hamiltonians, and extended coupled cluster (ECC). Diagrams use Kállay–Surján integer notation and are rendered with [Fletcher](https://typst.app/universe/package/fletcher/). Drawing requires Typst, not Python.

The project is maintained in three independent sibling repositories:

| Repository | Contents |
|:-----------|:---------|
| **ccdiagrams** (this repository) | `lib.typ`, Typst package metadata, examples, rendering tests |
| [ccdiagrams-generator](../ccdiagrams-generator/) | Python generator, CLI, enumeration and counting tests |
| [ccdiagrams-paper](../ccdiagrams-paper/) | Manuscript, bibliography, compiled PDF, reproduction instructions |

The existing combined-project Git history remains here. The generator and paper started with snapshots of the split state; their current sources are no longer duplicated here. Repository links above assume sibling checkouts; no remote hosting is configured by this split.

## Quick start

```typ
#import "lib.typ": goldstone, kallay-label

#goldstone("220 000 000 000 4")
#kallay-label("220 000 000 000 4")
#goldstone("111 220 7")
#goldstone("111 111 220 10")
#goldstone("220 222 10")
```

See [`examples/basic.typ`](examples/basic.typ) and its [PDF](examples/basic.pdf).
From this repository root:

```sh
typst compile --root . examples/basic.typ examples/basic.pdf
typst compile --root . examples/operators.typ examples/operators.pdf
```

The library requires Typst 0.13.0 or later and imports `@preview/fletcher:0.5.8`.
First use needs access to the Typst package registry unless the dependency is already cached. Development tests were last run with Typst 0.15.1.

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

These counts give the lower annihilation capacities, not all orbital indices of the matrix element. Equation diagrams use all these capacities; operator diagrams may leave some uncontracted. Vertices 11 and 12 are bare contributions, written simply as `"11"` and `"12"`.

All fields must be non-negative integers, and `η` must be between 0 and 12. Amplitude triplets are ordered lexicographically: excitation levels are nondecreasing; equal excitation levels have nondecreasing internal-line counts; and equal excitation levels and internal-line counts have nondecreasing internal particle-line counts.

Trailing `000` amplitudes can be omitted, so `"220 4"` and `"220 000 000 000 4"` are equivalent. For fields greater than nine, delimit a triplet with `/`, `:`, or `,`. Structured input is also accepted:

```typ
#goldstone("10/1/1 0")
#goldstone(((2, 2, 0), (0, 0, 0), 4))
```

`goldstone` checks that amplitude ranks and line counts are valid and do not exceed the interaction's particle/hole capacities. Use `mode: "equation"` to require complete contraction of the Hamiltonian annihilation lines.

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

The same `goldstone` function accepts partial-contraction tuples and nested ECC tuples, without converting either to projected equation diagrams:

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

ECC input is `(base, rows)`, where each row is `(rank, ((p_H, h_H), (p_T1, h_T1), ...))`. The base accepts any Kállay form above, including compact strings. A dictionary `(base: ..., rows: ...)` is also accepted. Columns refer to H followed by **active** T vertices, not the four padded slots. S rows have no padding or four-vertex limit. The renderer preserves their supplied order and incidence, checking connectivity, row rank bounds, and cumulative source capacities. `parse-diagram` returns the validated model; `diagram-signature` returns the four external quasiparticle counts. `kallay-label` also accepts partially contracted base tuples.

Layout selection:

- `mode: "auto"` (default): preserves the equation layout when there are no S vertices and all H annihilation lines are contracted; otherwise uses the layered operator/ECC layout.
- `mode: "operator"`: forces the layered layout, including scalar and pure-creation sectors.
- `mode: "ecc"`: requires nested ECC input and uses the layered layout.
- `mode: "equation"`: retains strict equation validation and the old layout.

The layered layout puts T below H and S above H. When both cluster families are present, H moves to the side so T–S edges do not pass through unrelated Hamiltonian vertices. Creation legs are short upward stubs; annihilation legs are short downward stubs. They do not share a projection boundary. Particle arrows run from creation to annihilation endpoints; hole arrows run oppositely. Coincident opposite-species contractions form curved lenses. Crossings without a marker are **not** vertices. T uses solid bars with filled black circles; S uses **wavy lines with filled black squares**, with one fermionic site per rank. S1 lines extend 5 pt on either side of their marker so the wave remains visible. H retains its dashed line and open circles. Dense diagrams can still have crossings.

Styling options above also apply here; the layered defaults are `arrows: "all"` and `mark-scale: 85%`. Use `labels: true` for T/S ranks and H's vertex number. For canonical-coordinate energy graphs, set `excitation-symbol: $Sigma$` to label the excitation bars accordingly. This changes labels only: rendering neither filters diagrams nor performs an amplitude-coordinate transformation.

See [`examples/operators.typ`](examples/operators.typ) and its [PDF](examples/operators.pdf) for all thirteen bare vertices, partial contractions, inequivalent ECC scalar graphs, and a twelve-S-vertex example.

## Generating input in the separate repository

The Python generator and its APIs now live in [ccdiagrams-generator](../ccdiagrams-generator/). No Python module is bundled with this library. With sibling checkouts, run from this repository root:

```sh
python3 ../ccdiagrams-generator/generate_kallay.py 1 --mode ecc --json > ecc.json
```

Or install the generator separately and use `ccdiagrams-generate 1 --mode ecc --json`. Save the following as `render.typ` beside `ecc.json` and `lib.typ`:

```typ
#import "lib.typ": goldstone
#set page(width: auto, height: auto)
#let diagrams = json("ecc.json")
#grid(columns: 4, gutter: 4mm,
  ..diagrams.slice(0, calc.min(24, diagrams.len())).map(d => goldstone(d)),
)
```

Compile with `typst compile render.typ render.pdf`. Equation-mode JSON is a rank-keyed object: select a rank first with `json("equations.json").at("2")`. Other modes produce arrays. No tuple conversion or orbital labels are needed. The generator enumerates topologies, not signs or algebraic weights. See the [paper repository](../ccdiagrams-paper/) for derivations and the distinction between original and canonical ECC amplitude coordinates.

## Development and tests

The seven self-contained rendering tests need Python 3.10+ and `typst` on `PATH`, but **not** the generator:

```sh
python3 -m unittest discover -s tests -v
```

Without the generator, the three generator-backed integration tests are explicitly skipped. Those tests compile all CCSDT equation tuples and small operator hierarchies, and check incidence, signatures, and port conservation for 2,081 rendering plans. To run all ten tests, install the generator as a **development-only** dependency (the requirements file assumes sibling checkouts):

```sh
uv venv .venv
uv pip install --python .venv/bin/python -r requirements-dev.txt
.venv/bin/python -c 'import generate_kallay'  # Ensure integration tests are enabled.
.venv/bin/python -m unittest discover -s tests -v
```

Alternatively use `python3 -m venv .venv` and `.venv/bin/python -m pip install -r requirements-dev.txt`. For checkouts elsewhere, install `-e /path/to/ccdiagrams-generator` instead. Missing Typst skips the rendering tests; installing the generator never becomes a runtime requirement for drawing.

## Reference

M. Kállay and P. R. Surján, “Higher excitations in coupled-cluster theory,” *J. Chem. Phys.* **115**, 2945–2954 (2001), [doi:10.1063/1.1383290](https://doi.org/10.1063/1.1383290), especially Eq. (8) and Fig. 1.
