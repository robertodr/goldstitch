"""Typst regressions; three integration tests optionally use the generator.

Install requirements-dev.txt to enable all tests. The renderer itself and the
remaining tests do not depend on the Python generator or a sibling checkout.
"""

from collections import Counter
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

try:
    from generate_kallay import (
        generate_diagrams, generate_similarity_transformed, external_signature,
    )
except ModuleNotFoundError as error:
    if error.name != "generate_kallay":
        raise
    HAS_GENERATOR = False
else:
    HAS_GENERATOR = True

requires_generator = unittest.skipUnless(
    HAS_GENERATOR,
    "install ccdiagrams-generator (requirements-dev.txt) for integration tests",
)


ROOT = Path(__file__).resolve().parents[1]


@unittest.skipUnless(shutil.which("typst"), "typst is not installed")
class TypstTests(unittest.TestCase):
    def compile_source(self, source, *, files=None, query=False):
        with tempfile.TemporaryDirectory(dir=ROOT / "tests") as directory:
            source_path = Path(directory) / "test.typ"
            source_path.write_text(
                '#import "/lib.typ": parse-kallay, goldstone, parse-diagram, '
                'diagram-signature, _operator-layout\n' + source,
                encoding="utf-8",
            )
            for name, content in (files or {}).items():
                (Path(directory) / name).write_text(content, encoding="utf-8")
            command = ["typst", "query" if query else "compile",
                       "--root", str(ROOT), str(source_path)]
            command += (["<graphs>", "--field", "value"] if query
                        else [str(Path(directory) / "test.pdf")])
            return subprocess.run(command, capture_output=True, text=True, timeout=120)

    @requires_generator
    def test_all_ccsdt_diagrams(self):
        codes = [
            " ".join("/".join(map(str, triplet)) for triplet in code[:-1])
            + f" {code[-1]}"
            for diagrams in generate_diagrams(3).values()
            for code in diagrams
        ]
        result = self.compile_source(
            '#set page(width: auto, height: auto)\n'
            '#grid(columns: 6, gutter: 4mm,\n'
            + "\n".join(f'goldstone("{code}"),' for code in codes)
            + '\n)'
        )
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_symmetric_layout(self):
        result = self.compile_source('#include "/tests/layout.typ"')
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_triplet_forms(self):
        for token in ("220", "(220)", "[220]", "{220}",
                      "2/2/0", "(2,2,0)", "[2:2:0]", "{2/2/0}"):
            with self.subTest(token=token):
                result = self.compile_source(
                    f'#assert(parse-kallay("{token} 4").amplitudes == ((2, 2, 0),))'
                )
                self.assertEqual(result.returncode, 0, result.stderr)

    @requires_generator
    def test_operator_drawings(self):
        records = [{"code": d, "mode": "operator"}
                   for d in generate_similarity_transformed(2)]
        result = self.compile_source(
            '#set page(width: auto, height: auto)\n'
            '#grid(columns: 8, gutter: 3mm, ..json("diagrams.json").map('
            'record => goldstone(record.code, mode: record.mode)))',
            files={"diagrams.json": json.dumps(records)},
        )
        self.assertEqual(result.returncode, 0, result.stderr)

    @requires_generator
    def test_drawn_port_graphs(self):
        # Independent Python signatures versus the actual Typst rendering plan.
        diagrams = generate_similarity_transformed(2)
        signatures = [external_signature(d) for d in diagrams]
        result = self.compile_source(
            '#metadata(json("diagrams.json").map(code => {\n'
            '  let graph = _operator-layout(parse-diagram(code))\n'
            '  (signature: diagram-signature(code), vertices: graph.vertices,\n'
            '    segments: graph.segments.map(s => (creator: s.creator,\n'
            '      annihilator: s.annihilator, kind: s.kind, external: s.external,\n'
            '      tail: s.tail, head: s.head, from: s.from, to: s.to)))\n'
            '})) <graphs>',
            files={"diagrams.json": json.dumps(diagrams)}, query=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        graphs = json.loads(result.stdout)[0]
        self.assertEqual(len(graphs), len(diagrams))
        for code, signature, graph in zip(diagrams, signatures, graphs):
            with self.subTest(code=code):
                self.assertEqual(tuple(graph["signature"]), signature)
                segments = graph["segments"]
                counts = Counter((s["external"], s["kind"]) for s in segments)
                self.assertEqual(tuple(counts[e, k]
                                       for e in ("creation", "annihilation")
                                       for k in ("p", "h")), signature)
                # Every fermionic site has exactly one incoming and outgoing
                # electron line. No port may be silently dropped or reused.
                outgoing = Counter(s["tail"] for s in segments)
                incoming = Counter(s["head"] for s in segments)
                for vertex in graph["vertices"]:
                    self.assertEqual(outgoing[vertex["id"]], 1)
                    self.assertEqual(incoming[vertex["id"]], 1)
                self.assertEqual(len(graph["vertices"]) * 2 + sum(signature),
                                 len(segments) * 2)
                for s in segments:
                    self.assertGreater(s["from"][1], s["to"][1])
                    self.assertEqual((s["tail"], s["head"]),
                                     (s["creator"], s["annihilator"])
                                     if s["kind"] == "p" else
                                     (s["annihilator"], s["creator"]))
                active = [a for a in code[:-1] if a[0]]
                for j, (_, internal, particles) in enumerate(active):
                    ht = Counter(s["kind"] for s in segments
                                 if s["creator"].startswith(f"t{j}:")
                                 and s["annihilator"].startswith("h"))
                    self.assertEqual((ht["p"], ht["h"]),
                                     (particles, internal - particles))

    def test_operator_examples_and_input_forms(self):
        result = self.compile_source(
            '#include "/examples/operators.typ"\n'
            '#assert(diagram-signature("211 10") == (1, 2, 1, 2))\n'
            '#assert(diagram-signature("12") == (2, 2, 0, 0))\n'
            '#assert(diagram-signature("242 10") == (0, 0, 0, 0))\n'
            '#goldstone("12", mode: "operator", arrows: "minimal",\n'
            '  level-gap: 8mm, leg-angle: 35deg, labels: true)\n'
            '#goldstone(parse-diagram("211 10"), labels: true, '
            'excitation-symbol: $T$)\n'
            '#goldstone(parse-diagram("221 2"), mode: "equation")\n'
            '#goldstone(parse-diagram("221 2"), labels: true, '
            'excitation-symbol: $Sigma$)\n'
            '#goldstone((amplitudes: ((2, 1, 1),), interaction: 10))\n'
            '#goldstone("211 10", mode: "operator", arrows: "all",\n'
            '  spacing: 9mm, loop-bend: 40deg, t1-bar-extension: 3pt)'
        )
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_invalid_modes(self):
        for code, message in (
            ('"211 10", mode: "equation"', 'requires 2 particle and 2 hole'),
            ('"11", mode: "ecc"', '`mode` must be'),
            ('"11", mode: "invalid"', '`mode` must be'),
            ('"0", arrows: "invalid"', '`arrows` must be'),
        ):
            with self.subTest(code=code):
                result = self.compile_source(f'#goldstone({code})')
                self.assertNotEqual(result.returncode, 0)
                self.assertIn('ccdiagrams:', result.stderr)
                self.assertIn(message, result.stderr)

    def test_rejects_nested_inputs(self):
        # Operator input must not silently accept de-excitation incidence rows.
        for code in (
            '("12", ((1, ((1, 1),)),))',
            '(base: "12", rows: ((1, ((1, 1),)),))',
            '("11", ())',
        ):
            with self.subTest(code=code):
                for function in ("parse-diagram", "diagram-signature", "goldstone"):
                    result = self.compile_source(f'#{function}({code})')
                    self.assertNotEqual(result.returncode, 0)
                    self.assertIn("ccdiagrams:", result.stderr)

    def test_malformed_triplets(self):
        for token, message in (
            ("2(2]0", "misplaced or mismatched brackets"),
            ("(220]", "misplaced or mismatched brackets"),
            ("220)", "misplaced or mismatched brackets"),
            ("((220))", "misplaced or mismatched brackets"),
            ("2//2/0", "empty field"),
            ("/2/2/0", "empty field"),
            ("2/2/0/", "empty field"),
            ("2/2", "must contain three integers"),
        ):
            with self.subTest(token=token):
                result = self.compile_source(f'#goldstone("{token} 4")')
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("ccdiagrams:", result.stderr)
                self.assertIn(message, result.stderr)

    def test_invalid_amplitude_counts(self):
        for code, message in (
            ("111 111 111 111 111 3", "expected up to four amplitude triplets"),
            ("130 4", "invalid internal-line counts"),
            ("100 0", "needs an internal line"),
            ("111 4", "requires 0 particle and 2 hole internal lines"),
        ):
            with self.subTest(code=code):
                result = self.compile_source(f'#goldstone("{code}")')
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("ccdiagrams:", result.stderr)
                self.assertIn(message, result.stderr)


if __name__ == "__main__":
    unittest.main()
