"""Exact, reproducible checks for diagram-count-derivation.typ.

Run from the repository root:
    python -m unittest discover -s tests -p 'test_diagram_count_derivation.py' -v

The count formula and polynomial construction are deliberately kept separate
from generate_kallay.py, which constructs canonical diagrams explicitly.
"""

from collections import Counter
from fractions import Fraction
from math import comb
import unittest

from generate_kallay import generate_equation


def stable_count(k):
    """Manuscript's unified eventual quasipolynomial, with initial corrections."""
    numerator = (
        2 * k**3 + 78 * k**2 + 529 * k + 321 + (3 * k + 63) * (-1)**k
    )
    assert numerator % 48 == 0
    return numerator // 48 - 5 * (k == 0) - 3 * (k == 1) + (k == 2)


def diagram_count(n, k):
    """Closed count on the manuscript's domain (integer ranks 0 <= k <= n)."""
    if n == k == 0:
        return 0
    return stable_count(k) - 7 * (n == k) - (n == k + 1)


def add(*polynomials):
    result = [0] * max(map(len, polynomials))
    for polynomial in polynomials:
        for degree, value in enumerate(polynomial):
            result[degree] += value
    return result


def multiply(a, b):
    result = [0] * (len(a) + len(b) - 1)
    for i, ai in enumerate(a):
        for j, bj in enumerate(b):
            result[i + j] += ai * bj
    return result


def coefficient(polynomial, degree):
    return polynomial[degree] if 0 <= degree < len(polynomial) else 0


def hamiltonian_polynomials(n):
    """Return (polynomial, coefficient shift), indexed by Hamiltonian eta."""
    e = [0] + [1] * n
    b = [int(rank >= 2) for rank in range(n + 1)]
    e2 = multiply(e, e)
    diagonal = [0] * (2 * n + 1)
    for rank in range(1, n + 1):
        diagonal[2 * rank] = 1
    q_numerator = add(e2, diagonal)
    assert all(c % 2 == 0 for c in q_numerator)
    q = [c // 2 for c in q_numerator]
    a20 = add(b, q)
    a11 = add(e, e2)
    a21 = add(b, multiply(b, e), e2, multiply(q, e))
    eb = multiply(e, b)
    bq = multiply(b, q)
    a22 = add(
        b, eb, eb, multiply(b, b), q, bq, bq,
        multiply(e2, e), multiply(q, q),
    )
    return (
        (e, 0), (e, 0), (a11, 1), (a20, 0), (a20, 0),
        (a11, 0), (a21, 1), (a21, 1), (e, -1), (e, -1),
        (a22, 2), ([1], -1), ([1], -2),
    )


class DiagramCountDerivationTests(unittest.TestCase):
    def test_all_equations_through_rank_20(self):
        cases = 0
        for n in range(21):
            polynomials = hamiltonian_polynomials(n)
            for k in range(n + 1):
                with self.subTest(n=n, k=k):
                    diagrams = generate_equation(n, k)
                    by_vertex = Counter(diagram[-1] for diagram in diagrams)
                    expected = [
                        coefficient(polynomial, k + shift)
                        for polynomial, shift in polynomials
                    ]
                    self.assertEqual(
                        [by_vertex[eta] for eta in range(13)], expected
                    )
                    self.assertEqual(sum(expected), diagram_count(n, k))
                    self.assertEqual(len(diagrams), diagram_count(n, k))
                    cases += 1
        self.assertEqual(cases, 231)

    def test_stable_rational_function_and_partial_fractions(self):
        maximum = 80
        polynomials = hamiltonian_polynomials(maximum + 2)
        stable_coefficients = [
            sum(coefficient(p, k + shift) for p, shift in polynomials)
            for k in range(maximum + 1)
        ]
        # Multiply the computed series by (1-x)^4 (1+x)^2.
        denominator = multiply([1, -4, 6, -4, 1], [1, 2, 1])
        numerator = [3, 9, 5, -25, -8, 21, 0, -5, 1]
        product = multiply(stable_coefficients, denominator)
        self.assertEqual(
            product[:maximum + 1],
            numerator + [0] * (maximum + 1 - len(numerator)),
        )
        for k, value in enumerate(stable_coefficients):
            with self.subTest(k=k):
                partial_fraction_value = (
                    -5 * (k == 0) - 3 * (k == 1) + (k == 2)
                    - Fraction(11, 4)
                    + Fraction(103, 16) * (k + 1)
                    + Fraction(11, 4) * comb(k + 2, 2)
                    + Fraction(1, 4) * comb(k + 3, 3)
                    + Fraction(5, 4) * (-1)**k
                    + Fraction(1, 16) * (-1)**k * (k + 1)
                )
                self.assertEqual(value, partial_fraction_value)
                self.assertEqual(value, stable_count(k))

    def test_published_polynomial_and_low_rank_conventions(self):
        for k in range(2, 81):
            na = Fraction(k**3, 24) + Fraction(13 * k**2, 8) + Fraction(133 * k, 12) + 1
            base = na if k % 2 == 0 else na - Fraction(5, 2) - Fraction(k + 1, 8)
            for offset, increment in ((0, 0), (1, 6), (2, 7)):
                with self.subTest(k=k, offset=offset):
                    self.assertEqual(
                        diagram_count(k + offset, k),
                        base + increment + (k == 2),
                    )
        self.assertEqual(diagram_count(1, 1), 7 + 1)

    def test_manuscript_table(self):
        table = (
            (0,),
            (2, 8),
            (3, 14, 31),
            (3, 15, 37, 47),
            (3, 15, 38, 53, 74),
            (3, 15, 38, 54, 80, 99),
            (3, 15, 38, 54, 81, 105, 135),
        )
        for n, row in enumerate(table):
            self.assertEqual(tuple(diagram_count(n, k) for k in range(n + 1)), row)


if __name__ == "__main__":
    unittest.main()
