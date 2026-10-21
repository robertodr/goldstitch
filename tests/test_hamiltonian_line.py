"""Check Hamiltonian styling in the actual SVG output, without a generator."""

from collections import Counter
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[1]
SVG_PATH = "{http://www.w3.org/2000/svg}path"


@unittest.skipUnless(shutil.which("typst"), "typst is not installed")
class HamiltonianLineTests(unittest.TestCase):
    def render(self, code, mode, line=None, *, stroke="0.65pt"):
        with tempfile.TemporaryDirectory(dir=ROOT / "tests") as directory:
            source = Path(directory) / "diagram.typ"
            output = source.with_suffix(".svg")
            option = "" if line is None else f", hamiltonian-line: {line}"
            source.write_text(
                '#import "/lib.typ": goldstone\n'
                '#import "@preview/fletcher:0.5.8" as fletcher\n'
                '#set page(width: auto, height: auto, margin: 0pt)\n'
                f'#goldstone("{code}", mode: "{mode}", stroke: {stroke}{option})',
                encoding="utf-8",
            )
            result = subprocess.run(
                ["typst", "compile", "--root", str(ROOT), str(source), str(output)],
                capture_output=True, text=True, timeout=120,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            def collect_paths(element, transforms=()):
                # Typst 0.13 puts translations on groups; newer SVGs flatten
                # them onto paths. Keep both so spacing checks use page space.
                if "transform" in element.attrib:
                    transforms += (element.attrib["transform"],)
                if element.tag == SVG_PATH:
                    yield {**element.attrib, "_transforms": transforms}
                for child in element:
                    yield from collect_paths(child, transforms)

            return list(collect_paths(ET.parse(output).getroot()))

    def hamiltonian_paths(self, paths, *, width=0.455):
        # The Hamiltonian is thinner than all other stroked elements by default.
        return [path for path in paths
                if abs(float(path.get("stroke-width", 0)) - width) < 1e-6]

    def other_paths(self, paths):
        return Counter(tuple(sorted(path.items())) for path in paths
                       if path not in self.hamiltonian_paths(paths))

    def test_default_preserves_existing_dash_and_stroke(self):
        for code, mode in (("221 2", "equation"), ("221 10", "operator"),
                           ("221 10", "auto"), ("242 10", "auto")):
            with self.subTest(code=code, mode=mode):
                baseline = self.render(code, mode)
                hamiltonian = self.hamiltonian_paths(baseline)
                self.assertEqual(len(hamiltonian), 1)
                self.assertEqual(hamiltonian[0]["stroke-dasharray"], "1 1.25")
                for option in ('"default"', '"dashed"', '(:)',
                               '(style: "default")'):
                    self.assertEqual(self.render(code, mode, option), baseline)
                scaled = self.render(code, mode, '"default"', stroke="1pt")
                self.assertEqual(len(self.hamiltonian_paths(scaled, width=0.7)), 1)

    def test_presets_change_only_the_hamiltonian_line(self):
        for code, mode in (("221 2", "equation"), ("221 10", "operator")):
            with self.subTest(mode=mode):
                baseline = self.render(code, mode)
                solid = self.render(code, mode, '"solid"')
                double = self.render(code, mode, '"double"')
                dotted = self.render(code, mode, '"dotted"')
                wavy = self.render(code, mode, '"wavy"')
                self.assertEqual(len(self.hamiltonian_paths(solid)), 1)
                self.assertEqual(len(self.hamiltonian_paths(double)), 2)
                for paths in (solid, double, wavy):
                    self.assertTrue(self.hamiltonian_paths(paths))
                    self.assertTrue(all("stroke-dasharray" not in path
                                        for path in self.hamiltonian_paths(paths)))
                self.assertNotEqual(self.hamiltonian_paths(dotted)[0]["stroke-dasharray"],
                                    "1 1.25")
                self.assertTrue(any("c" in path["d"].lower()
                                    for path in self.hamiltonian_paths(wavy)))
                for paths in (solid, double, dotted, wavy):
                    self.assertEqual(self.other_paths(paths), self.other_paths(baseline))

    def test_dictionary_overrides_stroke_dash_and_double_separation(self):
        for code, mode in (("221 2", "equation"), ("221 10", "operator")):
            with self.subTest(mode=mode):
                paths = self.render(code, mode,
                    '(style: "double", stroke: rgb("d02090") + 0.9pt, '
                    'dash: (array: (3pt, 1pt), phase: 0.5pt), '
                    'extrude: (-1.5pt, 1.5pt))')
                colored = [path for path in paths if path.get("stroke") == "#d02090"]
                self.assertEqual(len(colored), 2)
                for path in colored:
                    self.assertAlmostEqual(float(path["stroke-width"]), 0.9)
                    self.assertEqual(path["stroke-dasharray"], "3 1")
                    self.assertAlmostEqual(float(path["stroke-dashoffset"]), 0.5)
                ys = []
                for path in colored:
                    y = 0
                    for transform in path["_transforms"]:
                        self.assertTrue(transform.startswith("translate("), transform)
                        xy = list(map(float, re.findall(
                            r"-?\d+(?:\.\d+)?", transform)))
                        # translate(x) has an implicit zero y.
                        y += xy[1] if len(xy) == 2 else 0
                    ys.append(y)
                self.assertAlmostEqual(abs(ys[1] - ys[0]), 3)
                # A dictionary without a style starts from the dashed default.
                default = self.render(code, mode, '(stroke: rgb("d02090") + 0.9pt)')
                colored = [path for path in default if path.get("stroke") == "#d02090"]
                self.assertEqual(len(colored), 1)
                self.assertEqual(colored[0]["stroke-dasharray"], "1 1.25")

    def test_wave_geometry_and_custom_decorations(self):
        for code, mode in (("221 2", "equation"), ("221 10", "operator")):
            with self.subTest(mode=mode):
                default = self.render(code, mode, '"wavy"')
                custom = self.render(code, mode,
                    '(style: "wavy", wave: (amplitude: 2pt, segments: 4))')
                self.assertNotEqual(self.hamiltonian_paths(custom),
                                    self.hamiltonian_paths(default))
                zigzag = self.render(code, mode,
                    '(style: "solid", decorations: '
                    'fletcher.cetz.decorations.zigzag.with(amplitude: 1pt, segments: 3))')
                solid = self.render(code, mode, '"solid"')
                self.assertNotEqual(self.hamiltonian_paths(zigzag),
                                    self.hamiltonian_paths(solid))
                self.assertEqual(self.render(code, mode,
                    '(style: "wavy", decorations: none)'), solid)
        # A very short Hamiltonian must not fail the decoration's path-length check.
        self.render("221 2", "equation", '"wavy"', stroke="0.2pt")

    def test_invalid_styles_report_package_errors(self):
        for line, message in (
            ('42', 'string or dictionary'),
            ('"unknown"', 'Hamiltonian line style'),
            ('(style: 42)', 'Hamiltonian line style'),
            ('(style: "wavy", wave: 42)', '`wave` must be a dictionary'),
            ('(style: "solid", wave: (amplitude: 1pt))', 'require the `wavy` style'),
            ('(vertices: ((0, 0), (1, 0)))', '`vertices`'),
        ):
            with self.subTest(line=line):
                with tempfile.TemporaryDirectory(dir=ROOT / "tests") as directory:
                    source = Path(directory) / "invalid.typ"
                    source.write_text('#import "/lib.typ": goldstone\n'
                                      f'#goldstone("221 10", hamiltonian-line: {line})')
                    result = subprocess.run(
                        ["typst", "compile", "--root", str(ROOT), str(source),
                         str(source.with_suffix(".pdf"))],
                        capture_output=True, text=True, timeout=120,
                    )
                    self.assertNotEqual(result.returncode, 0)
                    self.assertIn("goldstitch:", result.stderr)
                    self.assertIn(message, result.stderr)


if __name__ == "__main__":
    unittest.main()
