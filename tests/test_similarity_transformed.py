"""Independent multiset-product checks for the full operator enumeration."""

from collections import Counter, defaultdict
import unittest

from generate_kallay import (
    HAMILTONIAN_VERTICES,
    count_similarity_transformed,
    external_signature,
    generate_equation,
    generate_similarity_transformed,
)


def multiset_coefficients(n):
    """Expand product (1-x**e u**p v**h)**-1 through u**2 v**2.

    This builds coefficients, not tuples, and is independent of the recursive
    enumeration and of the manuscript's five explicit contraction polynomials.
    """
    coefficients = {(0, 0, 0): 1}
    for e in range(1, n + 1):
        for p in range(min(e, 2) + 1):
            for h in range(min(e, 2) + 1):
                if p + h == 0:
                    continue
                updated = coefficients.copy()
                for (rank, particles, holes), value in coefficients.items():
                    copies = 1
                    while particles + copies * p <= 2 and holes + copies * h <= 2:
                        key = (rank + copies * e, particles + copies * p, holes + copies * h)
                        updated[key] = updated.get(key, 0) + value
                        copies += 1
                coefficients = updated
    return coefficients


def predicted_signatures(n):
    result = Counter()
    coefficients = multiset_coefficients(n)
    for eta, (p, h, p0, h0) in enumerate(HAMILTONIAN_VERTICES):
        for (rank, s, t), value in coefficients.items():
            if s <= p and t <= h:
                result[(eta, p0 + rank - s, h0 + rank - t, p - s, h - t)] += value
    return result


def sector_counts(n):
    """Positive-n formulas from the manuscript's annihilation-sector table."""
    return {
        (0, 0): (n**4 + 14 * n**3 + 47 * n**2 + 22 * n - 8) // 4,
        (1, 0): (n**3 + 8 * n**2 + 11 * n) // 2,
        (0, 1): (n**3 + 8 * n**2 + 11 * n) // 2,
        (2, 0): (n**2 + 5 * n) // 2,
        (0, 2): (n**2 + 5 * n) // 2,
        (1, 1): (n + 1) * (n + 2),
        (2, 1): n + 1,
        (1, 2): n + 1,
        (2, 2): 1,
    }


class SimilarityTransformedTests(unittest.TestCase):
    def test_full_operators_through_rank_20(self):
        for n in range(21):
            with self.subTest(n=n):
                diagrams = generate_similarity_transformed(n)
                self.assertEqual(diagrams, sorted(set(diagrams)))
                self.assertEqual(len(diagrams), count_similarity_transformed(n))
                actual = Counter((d[-1], *external_signature(d)) for d in diagrams)
                self.assertEqual(actual, predicted_signatures(n))
                sectors = Counter()
                body_ranks = set()
                for (_, cp, ch, ap, ah), count in actual.items():
                    self.assertGreaterEqual(min(cp, ch, ap, ah), 0)
                    self.assertEqual(cp - ap, ch - ah)
                    sectors[(ap, ah)] += count
                    body_ranks.add((cp + ch + ap + ah) // 2)
                if n > 0:
                    self.assertEqual(sectors, sector_counts(n))
                    self.assertEqual(max(body_ranks), 4 * n - 2)
                else:
                    self.assertEqual(body_ranks, {1, 2})

                # Projection of the new operator enumerator must recover the
                # original generator's exact tuples, not just the totals.
                projected = defaultdict(list)
                for diagram in diagrams:
                    cp, ch, ap, ah = external_signature(diagram)
                    if ap == ah == 0:
                        projected[cp].append(diagram)
                for k in range(n + 1):
                    self.assertEqual(projected[k], generate_equation(n, k))

    def test_structural_constraints(self):
        for diagram in generate_similarity_transformed(4):
            active = [a for a in diagram[:-1] if a != (0, 0, 0)]
            self.assertEqual(active, sorted(active))
            self.assertEqual(
                list(diagram[:-1]), active + [(0, 0, 0)] * (4 - len(active))
            )
            for e, internal, p in active:
                self.assertTrue(1 <= e <= 4)
                self.assertGreater(internal, 0)
                self.assertTrue(0 <= p <= e)
                self.assertTrue(0 <= internal - p <= e)

    def test_examples_and_bare_vertices(self):
        zero = (0, 0, 0)
        self.assertEqual(
            generate_similarity_transformed(0),
            [(zero, zero, zero, zero, eta) for eta in range(13)],
        )
        examples = (
            (((2, 2, 1), zero, zero, zero, 5), (2, 2, 0, 0)),
            (((2, 4, 2), zero, zero, zero, 10), (0, 0, 0, 0)),
            (((2, 1, 1), zero, zero, zero, 10), (1, 2, 1, 2)),
        )
        diagrams = generate_similarity_transformed(2)
        for diagram, signature in examples:
            self.assertIn(diagram, diagrams)
            self.assertEqual(external_signature(diagram), signature)
        self.assertNotIn(examples[-1][0], generate_equation(2, 2))

    def test_numerical_tables(self):
        self.assertEqual(
            [count_similarity_transformed(n) for n in range(6)],
            [13, 56, 183, 420, 809, 1398],
        )
        pure = Counter()
        for diagram in generate_similarity_transformed(2):
            cp, ch, ap, ah = external_signature(diagram)
            if ap == ah == 0:
                pure[cp] += 1
        self.assertEqual([pure[k] for k in range(7)], [3, 14, 31, 22, 13, 4, 1])

    def test_invalid_truncations(self):
        for function in (generate_similarity_transformed, count_similarity_transformed):
            for value in (-1, 1.5, "2", None, True, False):
                with self.subTest(function=function.__name__, value=value):
                    with self.assertRaises(ValueError):
                        function(value)


if __name__ == "__main__":
    unittest.main()
