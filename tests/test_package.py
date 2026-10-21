"""Exercise the published interface from an isolated, runtime-only package."""

from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]


@unittest.skipUnless(shutil.which("typst"), "typst is not installed")
class PackageTests(unittest.TestCase):
    def compile_package(self, source):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            registry = root / "registry"
            package = registry / "preview" / "goldstitch" / "0.1.0"
            package.mkdir(parents=True)
            # No tests, examples, generator, or source checkout are accessible
            # from the installed package: these four files must suffice.
            for name in ("typst.toml", "lib.typ", "README.md", "LICENSE"):
                shutil.copy2(ROOT / name, package / name)
            source_path = root / "document.typ"
            source_path.write_text(source, encoding="utf-8")
            return subprocess.run(
                ["typst", "compile", "--root", str(root),
                 "--package-path", str(registry), str(source_path),
                 str(root / "document.pdf")],
                capture_output=True, text=True, timeout=120,
            )

    def test_registry_import_exposes_public_api(self):
        result = self.compile_package(
            '#import "@preview/goldstitch:0.1.0": goldstone, kallay-label, '
            'parse-kallay, parse-diagram, diagram-signature\n'
            '#assert(parse-kallay("220 4").amplitudes == ((2, 2, 0),))\n'
            '#assert(diagram-signature(parse-diagram("221 10")) == (1, 1, 1, 1))\n'
            '#kallay-label("220 4")\n'
            '#goldstone("220 4")\n'
            '#goldstone("12", mode: "operator")\n'
            '#for style in ("default", "dashed", "solid", "dotted", "double", "wavy") {\n'
            '  goldstone("221 2", mode: "equation", hamiltonian-line: style)\n'
            '  goldstone("221 10", mode: "operator", hamiltonian-line: style)\n'
            '}\n'
            '#goldstone("221 10", hamiltonian-line: (style: "wavy", '
            'stroke: blue + 0.9pt, wave: (amplitude: 2pt, segments: 4)))\n'
        )
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_readme_examples_compile_with_registry_imports(self):
        snippets = re.findall(r"```typ\n(.*?)```", (ROOT / "README.md").read_text(
            encoding="utf-8"), flags=re.DOTALL)
        self.assertTrue(snippets, "README must demonstrate the public API")
        result = self.compile_package("\n".join(snippets))
        self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == "__main__":
    unittest.main()
