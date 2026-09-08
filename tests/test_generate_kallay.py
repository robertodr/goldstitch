"""Regression tests for connected coupled-cluster tuple generation."""

import json
from pathlib import Path
import subprocess
import sys
import unittest

from generate_kallay import (
    HAMILTONIAN_VERTICES, generate_diagrams, generate_equation,
    generate_similarity_transformed, generate_ecc, generate_ecc_energy,
)


SCRIPT = Path(__file__).resolve().parents[1] / "generate_kallay.py"
ZERO = (0, 0, 0)


class GeneratorTests(unittest.TestCase):
    def test_counts(self):
        for n, expected in enumerate([
            [0],
            [2, 8],
            [3, 14, 31],
            [3, 15, 37, 47],
            [3, 15, 38, 53, 74],
        ]):
            with self.subTest(n=n):
                equations = generate_diagrams(n)
                self.assertEqual(list(equations), list(range(n + 1)))
                self.assertEqual([len(ds) for ds in equations.values()], expected)
                for k, diagrams in equations.items():
                    self.assertEqual(diagrams, generate_equation(n, k))

    def test_reference_energy_excluded(self):
        self.assertEqual(generate_diagrams(0), {0: []})
        self.assertEqual(generate_equation(0, 0), [])

    def test_bare_vertices(self):
        for k, diagrams in generate_diagrams(4).items():
            bare = [d for d in diagrams if d[:4] == (ZERO,) * 4]
            expected = [(ZERO, ZERO, ZERO, ZERO, 10 + k)] if k in (1, 2) else []
            with self.subTest(k=k):
                self.assertEqual(bare, expected)

    def test_canonical_connected_and_conserved(self):
        for n in range(5):
            for k, diagrams in generate_diagrams(n).items():
                self.assertEqual(diagrams, sorted(set(diagrams)))
                for diagram in diagrams:
                    with self.subTest(n=n, k=k, diagram=diagram):
                        self.assertEqual(len(diagram), 5)
                        amplitudes = [a for a in diagram[:4] if a != ZERO]
                        self.assertEqual(amplitudes, sorted(amplitudes))
                        self.assertEqual(
                            diagram[:4], tuple(amplitudes) + (ZERO,) * (4 - len(amplitudes))
                        )
                        for rank, internal, particles in amplitudes:
                            self.assertTrue(1 <= rank <= n)
                            self.assertGreater(internal, 0)
                            self.assertTrue(0 <= particles <= rank)
                            self.assertTrue(0 <= internal - particles <= rank)
                        self.assertTrue(0 <= diagram[4] < 13)
                        ip, ih, ep, eh = HAMILTONIAN_VERTICES[diagram[4]]
                        self.assertEqual(sum(p for e, i, p in amplitudes), ip)
                        self.assertEqual(sum(i - p for e, i, p in amplitudes), ih)
                        self.assertEqual(ep + sum(e - p for e, i, p in amplitudes), k)
                        self.assertEqual(eh + sum(e - i + p for e, i, p in amplitudes), k)

    def test_invalid_arguments(self):
        for value in (-1, True, False, 1.5, "2", None):
            with self.subTest(value=value):
                with self.assertRaisesRegex(ValueError, "n must be a non-negative integer"):
                    generate_diagrams(value)
                with self.assertRaisesRegex(ValueError, "n must be a non-negative integer"):
                    generate_equation(value, 0)
                with self.assertRaisesRegex(ValueError, "k must be a non-negative integer"):
                    generate_equation(2, value)
        with self.assertRaisesRegex(ValueError, "k must not exceed"):
            generate_equation(1, 2)

    def test_cli_json(self):
        for args, expected in [
            (["2", "--json"], generate_diagrams(2)),
            (["2", "-k", "1", "--json"], {1: generate_equation(2, 1)}),
        ]:
            with self.subTest(args=args):
                result = subprocess.run(
                    [sys.executable, str(SCRIPT), *args],
                    capture_output=True, text=True, check=True,
                )
                self.assertEqual(json.loads(result.stdout), json.loads(json.dumps(expected)))

    def test_cli_operator_modes(self):
        for args, expected in (
            (["0", "--mode", "hbar"], generate_similarity_transformed(0)),
            (["1", "--mode", "ecc"], generate_ecc(1)),
            (["2", "--mode", "ecc-energy"], generate_ecc_energy(2)),
            (["2", "--mode", "ecc-energy", "--canonical-coordinates"],
             generate_ecc_energy(2, canonical_coordinates=True)),
            (["0", "--mode", "ecc-energy"], []),
        ):
            with self.subTest(args=args):
                result = subprocess.run(
                    [sys.executable, str(SCRIPT), *args, "--json"],
                    capture_output=True, text=True, check=True,
                )
                self.assertEqual(json.loads(result.stdout), json.loads(json.dumps(expected)))
                result = subprocess.run(
                    [sys.executable, str(SCRIPT), *args],
                    capture_output=True, text=True, check=True,
                )
                self.assertIn(f"({len(expected)} diagrams)", result.stdout.splitlines()[0])
                self.assertEqual(result.stdout.splitlines()[1:], list(map(str, expected)))

    def test_cli_text(self):
        result = subprocess.run(
            [sys.executable, str(SCRIPT), "1", "-k", "0"],
            capture_output=True, text=True, check=True,
        )
        diagrams = generate_equation(1, 0)
        self.assertEqual(
            result.stdout.splitlines(),
            [f"# k = 0 ({len(diagrams)} diagrams)", *map(str, diagrams)],
        )

    def test_cli_invalid_arguments(self):
        for args in (
            ["-1"], ["2", "-k", "-1"], ["1", "-k", "2"], ["abc"],
            ["1", "--mode", "hbar", "-k", "0"],
            ["1", "--mode", "ecc", "-k", "0"],
            ["1", "--mode", "ecc-energy", "-k", "0"],
            ["1", "--canonical-coordinates"],
            ["1", "--mode", "hbar", "--canonical-coordinates"],
            ["1", "--mode", "ecc", "--canonical-coordinates"],
            ["1", "--mode", "unknown"],
        ):
            with self.subTest(args=args):
                result = subprocess.run(
                    [sys.executable, str(SCRIPT), *args], capture_output=True, text=True,
                )
                self.assertEqual(result.returncode, 2)
                self.assertIn("error:", result.stderr)
                self.assertNotIn("Traceback", result.stderr)


if __name__ == "__main__":
    unittest.main()
