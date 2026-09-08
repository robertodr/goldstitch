"""ECC checks, including independent Burnside/orbit-product counts."""

from collections import Counter
from itertools import permutations, product
import unittest

from generate_kallay import (
    canonicalize_ecc,
    ecc_external_signature,
    # Unequal cutoffs are useful diagnostic limits, not the public ECC model.
    _generate_ecc as generate_ecc,
    _generate_ecc_energy as generate_ecc_energy,
    generate_ecc as generate_common_ecc,
    generate_ecc_energy as generate_common_ecc_energy,
    is_doubly_linked,
    HAMILTONIAN_VERTICES,
    count_similarity_transformed,
    external_signature,
    generate_equation,
    generate_similarity_transformed,
)

ZERO = (0, 0, 0)


def burnside_signatures(base, n_s, *, energy=False, doubly_linked=False):
    """Count graph orbits without constructing S multisets or ECC tuples.

    Fixed multisets have equal multiplicities on each orbit of S row TYPES.
    Multiply one geometric factor per orbit, bounding each source degree by
    its capacity; then average over permutations of equal base T vertices.
    """
    active = [a for a in base[:-1] if a[0]]
    _, _, p0, h0 = HAMILTONIAN_VERTICES[base[-1]]
    capacities = (p0, h0) + tuple(
        value for e, internal, p in active for value in (e - p, e - internal + p)
    )
    cp, ch, ap, ah = external_signature(base)
    if energy and (ap or ah):
        return Counter()
    types = set()
    for usage in product(*(range(c + 1) for c in capacities)):
        p, h = sum(usage[::2]), sum(usage[1::2])
        if p + h == 0:
            continue
        if doubly_linked and not (
            sum(usage[:2]) or sum(
                usage[i] + usage[i + 1] > 0 for i in range(2, len(usage), 2)
            ) >= 2
        ):
            continue
        for rank in range(1, n_s + 1):
            if p <= rank and h <= rank and (not energy or p == h == rank):
                types.add((rank, usage))
    group = [
        order for order in permutations(range(len(active)))
        if [active[i] for i in order] == active
    ]
    total = Counter()
    for order in group:
        columns = (0, 1) + tuple(j for i in order for j in (2 * i + 2, 2 * i + 3))
        unseen = types.copy()
        factors = []
        while unseen:
            first = next(iter(unseen))
            orbit = set()
            row = first
            while row not in orbit:
                orbit.add(row)
                rank, usage = row
                row = (rank, tuple(usage[i] for i in columns))
            unseen.difference_update(orbit)
            factors.append((
                sum(rank for rank, _ in orbit),
                tuple(sum(usage[i] for _, usage in orbit) for i in range(len(capacities))),
            ))
        coefficients = {(0, (0,) * len(capacities)): 1}
        for rank_step, degree_step in factors:
            updated = coefficients.copy()
            for (rank, degree), count in coefficients.items():
                next_degree = tuple(a + b for a, b in zip(degree, degree_step))
                next_rank = rank + rank_step
                while all(a <= b for a, b in zip(next_degree, capacities)):
                    key = (next_rank, next_degree)
                    updated[key] = updated.get(key, 0) + count
                    next_degree = tuple(a + b for a, b in zip(next_degree, degree_step))
                    next_rank += rank_step
            coefficients = updated
        for (rank, degree), count in coefficients.items():
            p, h = sum(degree[::2]), sum(degree[1::2])
            signature = cp - p, ch - h, ap + rank - p, ah + rank - h
            if not energy or signature == (0, 0, 0, 0):
                total[signature] += count
    result = Counter()
    for signature, count in total.items():
        quotient, remainder = divmod(count, len(group))
        if remainder:
            raise AssertionError("nonintegral Burnside average")
        result[signature] = quotient
    return result


class ECCTests(unittest.TestCase):
    def test_common_truncation_api(self):
        for n in (0, 1):
            self.assertEqual(generate_common_ecc(n), generate_ecc(n, n))
        for n in (0, 1, 2):
            for canonical in (False, True):
                diagrams = generate_common_ecc_energy(n, canonical_coordinates=canonical)
                self.assertEqual(
                    diagrams, generate_ecc_energy(n, n, canonical_coordinates=canonical)
                )
                for base, rows in diagrams:
                    rt = sum(e for e, _, _ in base[:-1])
                    rs = sum(r for r, _ in rows)
                    p, h, p0, h0 = HAMILTONIAN_VERTICES[base[-1]]
                    self.assertEqual(rt - rs, p - p0)
                    self.assertEqual(rt - rs, h - h0)
                    self.assertLessEqual(abs(rt - rs), 2)
                    self.assertLessEqual(rs, 4 * n - 2)
                    self.assertTrue(all(r <= n for r, _ in rows))
        for function in (generate_common_ecc, generate_common_ecc_energy):
            for value in (-1, True, False, 1.5, "2", None):
                with self.assertRaises(ValueError):
                    function(value)
        with self.assertRaises(ValueError):
            generate_common_ecc_energy(1, canonical_coordinates="yes")

    def test_single_transform_limits(self):
        for n in range(6):
            self.assertEqual(
                generate_ecc(n, 0),
                [(base, ()) for base in generate_similarity_transformed(n)],
            )
            # Reversing all quasiparticle arrows exchanges the T-only and
            # S-only problems, including the 13 bare Hamiltonian vertices.
            self.assertEqual(len(generate_ecc(0, n)), count_similarity_transformed(n))
            self.assertEqual(
                generate_ecc_energy(n, 0),
                [(base, ()) for base in generate_equation(n, 0)],
            )

    def test_full_operators_against_burnside(self):
        for n_t in range(2):
            for n_s in range(3):
                with self.subTest(n_t=n_t, n_s=n_s):
                    diagrams = generate_ecc(n_t, n_s)
                    self.assertEqual(diagrams, sorted(set(diagrams)))
                    actual = Counter((base, ecc_external_signature((base, rows)))
                                     for base, rows in diagrams)
                    expected = Counter()
                    for base in generate_similarity_transformed(n_t):
                        for signature, count in burnside_signatures(base, n_s).items():
                            expected[(base, signature)] = count
                    self.assertEqual(actual, expected)
                    self.assertEqual(
                        generate_ecc_energy(n_t, n_s),
                        [d for d in diagrams if ecc_external_signature(d) == (0, 0, 0, 0)],
                    )

    def test_larger_operator_counts(self):
        diagrams = generate_ecc(2, 1)
        actual = Counter((base, ecc_external_signature((base, rows)))
                         for base, rows in diagrams)
        expected = Counter()
        for base in generate_similarity_transformed(2):
            for signature, count in burnside_signatures(base, 1).items():
                expected[(base, signature)] = count
        self.assertEqual(actual, expected)
        self.assertEqual(len(diagrams), 42419)
        self.assertEqual(max(len(rows) for _, rows in diagrams), 12)
        # Count the full (2,2) operator without allocating millions of tuples.
        self.assertEqual(sum(
            sum(burnside_signatures(base, 2).values())
            for base in generate_similarity_transformed(2)
        ), 8743171)

    def test_energy_against_burnside(self):
        for n_s in (1, 2):
            for canonical in (False, True):
                with self.subTest(n_s=n_s, canonical=canonical):
                    diagrams = generate_ecc_energy(2, n_s, canonical_coordinates=canonical)
                    expected = Counter()
                    for base in generate_similarity_transformed(2):
                        count = burnside_signatures(
                            base, n_s, energy=True, doubly_linked=canonical
                        )[(0, 0, 0, 0)]
                        if count:
                            expected[base] = count
                    self.assertEqual(Counter(d[0] for d in diagrams), expected)
                    self.assertTrue(all(ecc_external_signature(d) == (0, 0, 0, 0)
                                        for d in diagrams))
                    if canonical:
                        self.assertTrue(all(is_doubly_linked(d) for d in diagrams))

    def test_incidence_is_essential(self):
        base = ((2, 2, 1), (2, 2, 1), ZERO, ZERO, 10)
        separate = (base, (
            (1, ((0, 0), (1, 1), (0, 0))),
            (1, ((0, 0), (0, 0), (1, 1))),
        ))
        crossed = (base, (
            (1, ((0, 0), (1, 0), (0, 1))),
            (1, ((0, 0), (0, 1), (1, 0))),
        ))
        a, b = canonicalize_ecc(separate), canonicalize_ecc(crossed)
        self.assertNotEqual(a, b)
        self.assertEqual(ecc_external_signature(a), (0, 0, 0, 0))
        self.assertEqual(ecc_external_signature(b), (0, 0, 0, 0))
        self.assertFalse(is_doubly_linked(a))
        self.assertTrue(is_doubly_linked(b))
        energy = generate_ecc_energy(2, 1)
        self.assertIn(a, energy)
        self.assertIn(b, energy)
        canonical_energy = generate_ecc_energy(2, 1, canonical_coordinates=True)
        self.assertNotIn(a, canonical_energy)
        self.assertIn(b, canonical_energy)
        # An S joined only to one T is allowed by the literal transform.
        single = (((2, 2, 1), ZERO, ZERO, ZERO, 2),
                  ((1, ((0, 0), (1, 1))),))
        self.assertIn(single, energy)
        self.assertNotIn(single, canonical_energy)

    def test_column_and_row_relabellings(self):
        group_sizes = set()
        for diagram in generate_ecc_energy(2, 1):
            base, rows = diagram
            active = [a for a in base[:-1] if a[0]]
            orders = [order for order in permutations(range(len(active)))
                      if [active[i] for i in order] == active]
            self.assertLessEqual(len(orders), 4)
            group_sizes.add(len(orders))
            for order in orders:
                relabelled = tuple(
                    (rank, (edges[0],) + tuple(edges[i + 1] for i in order))
                    for rank, edges in reversed(rows)
                )
                self.assertEqual(canonicalize_ecc((base, relabelled)), diagram)
        self.assertEqual(group_sizes, {1, 2, 4})

    def test_validity_and_unpadded_s(self):
        for base, rows in generate_ecc(1, 2):
            capacities = [(p0, h0) for _, _, p0, h0 in [HAMILTONIAN_VERTICES[base[-1]]]]
            capacities += [(e - p, e - internal + p) for e, internal, p in base[:-1] if e]
            for rank, edges in rows:
                self.assertTrue(1 <= rank <= 2)
                self.assertEqual(len(edges), len(capacities))
                self.assertGreater(sum(p + h for p, h in edges), 0)
                self.assertLessEqual(sum(p for p, _ in edges), rank)
                self.assertLessEqual(sum(h for _, h in edges), rank)
            for i, (p, h) in enumerate(capacities):
                self.assertLessEqual(sum(edges[i][0] for _, edges in rows), p)
                self.assertLessEqual(sum(edges[i][1] for _, edges in rows), h)
            cp, ch, ap, ah = ecc_external_signature((base, rows))
            self.assertGreaterEqual(min(cp, ch, ap, ah), 0)
            self.assertEqual(cp - ap, ch - ah)
        # Twelve singly attached S_1 vertices can occur at T_2 truncation.
        base = ((2, 1, 0), (2, 1, 0), (2, 1, 1), (2, 1, 1), 10)
        rows = []
        for column, capacities in enumerate(((2, 1), (2, 1), (1, 2), (1, 2)), 1):
            for species, count in enumerate(capacities):
                edges = [(0, 0)] * 5
                edges[column] = (1, 0) if species == 0 else (0, 1)
                rows.extend([(1, tuple(edges))] * count)
        diagram = canonicalize_ecc((base, tuple(rows)))
        self.assertEqual(len(diagram[1]), 12)
        self.assertEqual(ecc_external_signature(diagram), (0, 0, 6, 6))

    def test_small_count_table(self):
        for n_t, n_s, full, energy, canonical in (
            (0, 0, 13, 0, 0), (0, 1, 56, 2, 2), (0, 2, 183, 3, 3),
            (1, 0, 56, 2, 2), (1, 1, 395, 20, 20), (1, 2, 1598, 29, 29),
        ):
            self.assertEqual(len(generate_ecc(n_t, n_s)), full)
            self.assertEqual(len(generate_ecc_energy(n_t, n_s)), energy)
            self.assertEqual(len(generate_ecc_energy(n_t, n_s, canonical_coordinates=True)), canonical)
        self.assertEqual(len(generate_ecc_energy(2, 1)), 225)
        self.assertEqual(len(generate_ecc_energy(2, 2)), 1503)
        self.assertEqual(len(generate_ecc_energy(2, 1, canonical_coordinates=True)), 99)
        self.assertEqual(len(generate_ecc_energy(2, 2, canonical_coordinates=True)), 907)

    def test_invalid_ranks(self):
        for function in (generate_ecc, generate_ecc_energy):
            for value in (-1, True, False, 1.5, "2", None):
                for args in ((value, 1), (1, value)):
                    with self.assertRaises(ValueError):
                        function(*args)
        with self.assertRaises(ValueError):
            generate_ecc_energy(1, 1, canonical_coordinates="yes")


if __name__ == "__main__":
    unittest.main()
