#!/usr/bin/env python3
"""Generate connected Kállay--Surján coupled-cluster diagrams.

The public ``generate_diagrams`` function returns a dictionary mapping equation
ranks to lists of diagrams. Each diagram has the canonical tuple-of-tuples
representation

    ((epsilon_0, iota_0, pi_0), ..., (epsilon_3, iota_3, pi_3), eta)

with zero triplets used as padding.  The command-line interface prints one
Python tuple per line, grouped under equation headers (or JSON with ``--json``).
The energy equation contains correlation-energy contributions only; the scalar
reference energy is excluded.

``generate_similarity_transformed`` also retains Hamiltonian annihilation legs
that are not contracted with T. It enumerates the full normal-ordered operator
exp(-T) H_N exp(T), using the same tuples; ``external_signature`` recovers its
four external quasiparticle line counts.

``generate_ecc`` and ``generate_ecc_energy`` use a common rank cutoff for pure
excitation T and pure deexcitation S. ECC tuples are (base, rows), where base
is a Kallay operator tuple and each row is (rank, ((p_H,h_H), (p_T1,h_T1), ...)).
Columns refer to H and the ACTIVE T vertices; S rows have no padding. Every
T touches H and every S touches H or a T. The stronger doubly-linked rule is
only used for the energy in reparameterized canonical amplitude coordinates.
All APIs count topologies, not signs, Wick multiplicities or symmetry factors.

The CLI defaults to CC equations; --mode selects hbar, ecc, or ecc-energy.
"""

from __future__ import annotations

import argparse
import json
from itertools import combinations_with_replacement, permutations, product
from typing import Iterator

Amplitude = tuple[int, int, int]
Diagram = tuple[Amplitude, Amplitude, Amplitude, Amplitude, int]
Edge = tuple[int, int]
SVertex = tuple[int, tuple[Edge, ...]]
ECCDiagram = tuple[Diagram, tuple[SVertex, ...]]

# (internal particles, internal holes, external particles, external holes).
# These are the 13 vertices in Fig. 1 of Kállay and Surján, JCP 115, 2945
# (2001). "Internal" denotes lower annihilation capacity: only equation
# diagrams must contract all of it with T.
HAMILTONIAN_VERTICES: tuple[tuple[int, int, int, int], ...] = (
    (1, 0, 1, 0),  #  0: f_ab
    (0, 1, 0, 1),  #  1: f_ji
    (1, 1, 0, 0),  #  2: f_ia
    (2, 0, 2, 0),  #  3: <ad||bc>
    (0, 2, 0, 2),  #  4: <jk||il>
    (1, 1, 1, 1),  #  5: <ja||ib>
    (2, 1, 1, 0),  #  6: <ic||ab>
    (1, 2, 0, 1),  #  7: <ij||ak>
    (1, 0, 2, 1),  #  8: <ac||ib>
    (0, 1, 1, 2),  #  9: <aj||ik>
    (2, 2, 0, 0),  # 10: <ij||ab>
    (0, 0, 1, 1),  # 11: f_ai
    (0, 0, 2, 2),  # 12: <ab||ij>
)


def _bounded_compositions(total: int, bounds: tuple[int, ...]) -> Iterator[tuple[int, ...]]:
    """Yield ordered compositions, including zero parts, within ``bounds``."""
    if not bounds:
        if total == 0:
            yield ()
        return

    first, rest = bounds[0], bounds[1:]
    for value in range(min(first, total) + 1):
        for tail in _bounded_compositions(total - value, rest):
            yield (value,) + tail


def _canonical(amplitudes: tuple[Amplitude, ...]) -> bool:
    """Apply the hierarchical ordering rules of the compact representation."""
    return all(left <= right for left, right in zip(amplitudes, amplitudes[1:]))


def _rank_partitions(n: int, k: int) -> Iterator[tuple[int, ...]]:
    """Yield up-to-four-member T-rank partitions allowed for equation ``k``."""
    low, high = max(0, k - 2), k + 2
    # The empty partition is needed for bare Hamiltonian contributions.
    if low == 0:
        yield ()
    for length in range(1, 5):
        for ranks in combinations_with_replacement(range(1, n + 1), length):
            if low <= sum(ranks) <= high:
                yield ranks


def _validate_rank(value: int, name: str) -> None:
    if isinstance(value, bool) or not isinstance(value, int) or value < 0:
        raise ValueError(f"{name} must be a non-negative integer")


def generate_equation(n: int, k: int) -> list[Diagram]:
    """Return all canonical connected diagrams for the k-fold CC equation.

    ``n`` is the largest cluster rank present in the CC wavefunction.  Every
    nonzero T vertex is connected directly to the Hamiltonian, as required by
    the connected BCH expansion. For ``k = 0``, only correlation-energy
    contributions are included, so ``generate_equation(0, 0)`` returns ``[]``.
    """
    _validate_rank(n, "n")
    _validate_rank(k, "k")
    if k > n:
        raise ValueError("k must not exceed the CC truncation level n")

    diagrams: set[Diagram] = set()
    zero: Amplitude = (0, 0, 0)

    for ranks in _rank_partitions(n, k):
        length = len(ranks)
        total_rank = sum(ranks)
        for eta, (need_p, need_h, free_p, free_h) in enumerate(HAMILTONIAN_VERTICES):
            # External-line totals do not depend on the contraction distribution.
            if free_p + total_rank - need_p != k:
                continue
            if free_h + total_rank - need_h != k:
                continue
            # Distribute distinguishable particle/hole line types by their
            # counts.  This is equivalent to partitioning the internal lines
            # and then permuting the zero/one particle labels, but introduces
            # no duplicate permutations.
            for particles, holes in product(
                _bounded_compositions(need_p, ranks),
                _bounded_compositions(need_h, ranks),
            ):
                amplitudes = tuple(
                    (rank, p + h, p)
                    for rank, p, h in zip(ranks, particles, holes)
                )

                # Each T vertex must be linked to H; each rank-e amplitude has
                # at most e particle and e hole legs (already imposed by the
                # bounds above).
                if any(internal == 0 for _, internal, _ in amplitudes):
                    continue
                if not _canonical(amplitudes):
                    continue

                padded = amplitudes + (zero,) * (4 - length)
                diagrams.add((padded[0], padded[1], padded[2], padded[3], eta))

    return sorted(diagrams)


def generate_diagrams(n: int) -> dict[int, list[Diagram]]:
    """Map ranks 0 through ``n`` to diagrams, excluding scalar reference energy."""
    _validate_rank(n, "n")
    return {k: generate_equation(n, k) for k in range(n + 1)}


def external_signature(diagram: Diagram) -> tuple[int, int, int, int]:
    """Return (created particles, created holes, annihilated particles, holes).

    The input must be a valid canonical diagram. Counts refer to quasiparticles
    relative to the reference, not to electron creation/annihilation operators.
    An equation diagram has signature (k, k, 0, 0).
    """
    need_p, need_h, free_p, free_h = HAMILTONIAN_VERTICES[diagram[-1]]
    rank = sum(e for e, _, _ in diagram[:-1])
    particles = sum(p for _, _, p in diagram[:-1])
    holes = sum(i - p for _, i, p in diagram[:-1])
    return (
        free_p + rank - particles,
        free_h + rank - holes,
        need_p - particles,
        need_h - holes,
    )


def generate_similarity_transformed(n: int) -> list[Diagram]:
    """Enumerate expanded antisymmetrized topologies of exp(-T) H_N exp(T).

    Every T vertex is connected directly to H, but unused lower Hamiltonian
    legs are allowed. Equivalent choices of individual legs affect weights,
    not this topology count. All 13 bare H_N vertices and the generated
    correlation-energy scalar are included; the reference-energy scalar is
    excluded. No CC residuals are set to zero and no intermediates are formed.
    """
    _validate_rank(n, "n")
    zero: Amplitude = (0, 0, 0)
    diagrams: list[Diagram] = []

    for eta, (need_p, need_h, _, _) in enumerate(HAMILTONIAN_VERTICES):
        types = sorted(
            (e, p + h, p)
            for e in range(1, n + 1)
            for p in range(min(e, need_p) + 1)
            for h in range(min(e, need_h) + 1)
            if p + h > 0
        )

        def visit(
            amplitudes: tuple[Amplitude, ...], start: int, left_p: int, left_h: int
        ) -> None:
            padded = amplitudes + (zero,) * (4 - len(amplitudes))
            diagrams.append((padded[0], padded[1], padded[2], padded[3], eta))
            if left_p + left_h == 0:
                return
            # Nondecreasing type indices enumerate each multiset exactly once.
            # Reusing the index permits repeated identical cluster vertices.
            for index in range(start, len(types)):
                amplitude = types[index]
                _, internal, p = amplitude
                h = internal - p
                if p <= left_p and h <= left_h:
                    visit(amplitudes + (amplitude,), index, left_p - p, left_h - h)

        visit((), 0, need_p, need_h)

    return sorted(diagrams)


def count_similarity_transformed(n: int) -> int:
    """Closed total for the same unfactorized operator topologies as above."""
    _validate_rank(n, "n")
    if n == 0:
        return 13
    return (n**4 + 18 * n**3 + 87 * n**2 + 106 * n + 12) // 4


def _source_capacities(base: Diagram) -> tuple[Edge, ...]:
    _, _, p0, h0 = HAMILTONIAN_VERTICES[base[-1]]
    return ((p0, h0),) + tuple(
        (e - p, e - internal + p)
        for e, internal, p in base[:-1]
        if e > 0
    )


def _stabilizer(base: Diagram) -> Iterator[tuple[int, ...]]:
    """Permutations of active T positions that preserve their base triplets."""
    active = tuple(a for a in base[:-1] if a[0] > 0)
    for order in permutations(range(len(active))):
        if tuple(active[i] for i in order) == active:
            yield order


def _canonical_rows(
    rows: tuple[SVertex, ...], orders: tuple[tuple[int, ...], ...]
) -> tuple[SVertex, ...]:
    return min(
        tuple(sorted(
            (rank, (edges[0],) + tuple(edges[i + 1] for i in order))
            for rank, edges in rows
        ))
        for order in orders
    )


def canonicalize_ecc(diagram: ECCDiagram) -> ECCDiagram:
    """Canonicalize S rows and equal-T columns of an otherwise valid diagram.

    The base must already be a valid canonical Kallay--Surjan tuple. The
    four slots give a crude 4! bound, but P,H <= 2 permit at most two pairs
    of identical T types: at most FOUR admissible column permutations remain,
    regardless of the number of S rows.
    """
    base, rows = diagram
    return base, _canonical_rows(rows, tuple(_stabilizer(base)))


def ecc_external_signature(diagram: ECCDiagram) -> tuple[int, int, int, int]:
    """Return created p/h and annihilated p/h counts for a valid ECC tuple."""
    base, rows = diagram
    cp, ch, ap, ah = external_signature(base)
    rank = sum(r for r, _ in rows)
    particles = sum(p for _, edges in rows for p, _ in edges)
    holes = sum(h for _, edges in rows for _, h in edges)
    return cp - particles, ch - holes, ap + rank - particles, ah + rank - holes


def is_doubly_linked(diagram: ECCDiagram) -> bool:
    """Each S touches H or at least TWO DISTINCT T vertices.

    For scalar diagrams this is the canonical-coordinate ECC energy filter.
    It is NOT a validity requirement for the literal double similarity
    transform in independent, noncanonical T and S amplitude coordinates.
    """
    return all(
        sum(edges[0]) > 0 or sum(p + h > 0 for p, h in edges[1:]) >= 2
        for _, edges in diagram[1]
    )


def _s_types(
    capacities: tuple[Edge, ...], n_s: int, *, energy: bool, doubly_linked: bool
) -> list[SVertex]:
    types = []
    # Counts per source, rather than permutations of individual line labels.
    for particles in product(*(range(p + 1) for p, _ in capacities)):
        sum_p = sum(particles)
        if sum_p > n_s:
            continue
        for holes in product(*(range(h + 1) for _, h in capacities)):
            sum_h = sum(holes)
            if sum_h > n_s or sum_p + sum_h == 0:
                continue
            if energy and sum_p != sum_h:
                continue
            edges = tuple(zip(particles, holes))
            if doubly_linked and not (
                sum(edges[0]) > 0
                or sum(p + h > 0 for p, h in edges[1:]) >= 2
            ):
                continue
            low = max(1, sum_p, sum_h)
            high = low if energy else n_s
            types.extend((rank, edges) for rank in range(low, high + 1))
    return sorted(types)


def _decorate(
    base: Diagram, n_s: int, *, energy: bool, doubly_linked: bool
) -> Iterator[ECCDiagram]:
    _, _, ap, ah = external_signature(base)
    if energy and (ap != 0 or ah != 0):
        return  # S cannot remove an existing quasiparticle annihilator.
    capacities = _source_capacities(base)
    types = _s_types(capacities, n_s, energy=energy, doubly_linked=doubly_linked)
    orders = tuple(_stabilizer(base))
    seen: set[tuple[SVertex, ...]] = set()

    def visit(
        rows: tuple[SVertex, ...], start: int, left: tuple[Edge, ...]
    ) -> Iterator[ECCDiagram]:
        if not energy or all(p == h == 0 for p, h in left):
            canonical = _canonical_rows(rows, orders)
            if canonical not in seen:
                seen.add(canonical)
                yield base, canonical
        for index in range(start, len(types)):
            row = types[index]
            remaining = tuple(
                (p - used_p, h - used_h)
                for (p, h), (used_p, used_h) in zip(left, row[1])
            )
            if all(p >= 0 and h >= 0 for p, h in remaining):
                yield from visit(rows + (row,), index, remaining)

    yield from visit((), 0, capacities)


def _generate_ecc(n_t: int, n_s: int) -> list[ECCDiagram]:
    """Low-level unequal-cutoff construction, retained for diagnostic tests.

    With n_s=0 this reduces exactly to generate_similarity_transformed(n_t),
    decorated by empty S tuples. Partial S contractions and S vertices attached
    only to one T are intentionally retained. Large ranks can be expensive.
    """
    _validate_rank(n_t, "n_t")
    _validate_rank(n_s, "n_s")
    return sorted(
        diagram
        for base in generate_similarity_transformed(n_t)
        for diagram in _decorate(base, n_s, energy=False, doubly_linked=False)
    )


def _generate_ecc_energy(
    n_t: int, n_s: int, *, canonical_coordinates: bool = False
) -> list[ECCDiagram]:
    """Low-level scalar construction with independently supplied cutoffs.

    By default this is <Phi|exp(S)exp(-T)H_N exp(T)|Phi>. Setting
    canonical_coordinates=True instead applies the stronger doubly-linked
    ENERGY theorem in reparameterized canonical amplitudes. It does not
    assert an operator identity for the unmodified T and S of generate_ecc.
    """
    _validate_rank(n_t, "n_t")
    _validate_rank(n_s, "n_s")
    if not isinstance(canonical_coordinates, bool):
        raise ValueError("canonical_coordinates must be a boolean")
    return sorted(
        diagram
        for base in generate_similarity_transformed(n_t)
        for diagram in _decorate(
            base, n_s, energy=True, doubly_linked=canonical_coordinates
        )
    )


def generate_ecc(n: int) -> list[ECCDiagram]:
    """Full exp(S)exp(-T)H_N exp(T)exp(-S), retaining ranks 1..n in BOTH T,S.

    The amplitudes remain independent: a shared cutoff does not mean S=T^dagger.
    Partial contractions are retained. This reference enumerator is expensive
    already at n=2 (8,743,171 topologies); prefer energy-only generation when
    only the scalar is needed. No amplitude-coordinate reparameterization is
    applied to this operator construction.
    """
    _validate_rank(n, "n")
    return _generate_ecc(n, n)


def generate_ecc_energy(
    n: int, *, canonical_coordinates: bool = False
) -> list[ECCDiagram]:
    """Scalar ECC diagrams at a common rank-complete cutoff 1..n for T and S.

    Original coordinates give <Phi|exp(S)exp(-T)H_N exp(T)|Phi>. The canonical
    option uses Sigma with Q Sigma|Phi> = Q exp(S)T|Phi>, leaving S unchanged,
    and retains doubly-linked energy graphs in Sigma,S. These are equivalent
    energy functions at MAPPED amplitudes, not at identical numeric T,Sigma.
    Their stationary energies agree because this rank-lowering, invertible
    coordinate map preserves the rank-complete truncated amplitude space.
    """
    _validate_rank(n, "n")
    return _generate_ecc_energy(n, n, canonical_coordinates=canonical_coordinates)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Generate CC, similarity-transformed Hamiltonian, or ECC diagrams.",
        epilog="Full ECC grows rapidly: n=2 has 8,743,171 diagrams. "
               "Prefer ecc-energy when only scalar diagrams are needed.",
    )
    parser.add_argument("n", type=int, help="cluster truncation level (common to T and S in ECC)")
    parser.add_argument(
        "--mode", choices=("equations", "hbar", "ecc", "ecc-energy"),
        default="equations", help="construction to enumerate (default: equations)",
    )
    parser.add_argument(
        "--canonical-coordinates", action="store_true",
        help="doubly-linked energy in reparameterized amplitudes (ecc-energy only)",
    )
    parser.add_argument(
        "-k", "--equation", type=int,
        help="only generate the k-fold equation (default: k = 0,...,n)",
    )
    parser.add_argument("--json", action="store_true", help="emit JSON (rank object for equations, array otherwise)")
    args = parser.parse_args()

    if args.n < 0 or (args.equation is not None and args.equation < 0):
        parser.error("n and k must be non-negative")
    if args.equation is not None and args.equation > args.n:
        parser.error("k must not exceed the CC truncation level n")

    if args.mode != "equations" and args.equation is not None:
        parser.error("--equation is only valid with --mode equations")
    if args.canonical_coordinates and args.mode != "ecc-energy":
        parser.error("--canonical-coordinates is only valid with --mode ecc-energy")

    if args.mode != "equations":
        if args.mode == "hbar":
            diagrams = generate_similarity_transformed(args.n)
        elif args.mode == "ecc":
            diagrams = generate_ecc(args.n)
        else:
            diagrams = generate_ecc_energy(
                args.n, canonical_coordinates=args.canonical_coordinates
            )
        if args.json:
            print(json.dumps(diagrams, separators=(",", ":")))
        else:
            coordinates = " (canonical coordinates)" if args.canonical_coordinates else ""
            print(f"# {args.mode}{coordinates}, n = {args.n} ({len(diagrams)} diagrams)")
            for diagram in diagrams:
                print(diagram)
        return

    equations = (
        {args.equation: generate_equation(args.n, args.equation)}
        if args.equation is not None
        else generate_diagrams(args.n)
    )
    if args.json:
        print(json.dumps(equations, separators=(",", ":")))
    else:
        for k, diagrams in equations.items():
            print(f"# k = {k} ({len(diagrams)} diagrams)")
            for diagram in diagrams:
                print(diagram)


if __name__ == "__main__":
    main()
