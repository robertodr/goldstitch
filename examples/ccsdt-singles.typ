#import "../lib.typ": goldstone, kallay-label

#set page(width: auto, height: auto, margin: 8mm)
#set text(size: 10pt)

// All 15 antisymmetrized diagrams in the singles (k = 1) equations of CCSDT.
// From the renderer repository root, with sibling checkouts:
// python3 ../ccdiagrams-generator/generate_kallay.py 3 --equation 1
#let diagrams = (
  ((0, 0, 0), (0, 0, 0), (0, 0, 0), (0, 0, 0), 11),
  ((1, 1, 0), (0, 0, 0), (0, 0, 0), (0, 0, 0), 1),
  ((1, 1, 0), (1, 1, 1), (0, 0, 0), (0, 0, 0), 2),
  ((1, 1, 0), (1, 1, 1), (1, 2, 1), (0, 0, 0), 10),
  ((1, 1, 0), (1, 2, 1), (0, 0, 0), (0, 0, 0), 7),
  ((1, 1, 0), (2, 3, 2), (0, 0, 0), (0, 0, 0), 10),
  ((1, 1, 1), (0, 0, 0), (0, 0, 0), (0, 0, 0), 0),
  ((1, 1, 1), (1, 2, 1), (0, 0, 0), (0, 0, 0), 6),
  ((1, 1, 1), (2, 3, 1), (0, 0, 0), (0, 0, 0), 10),
  ((1, 2, 1), (0, 0, 0), (0, 0, 0), (0, 0, 0), 5),
  ((1, 2, 1), (2, 2, 1), (0, 0, 0), (0, 0, 0), 10),
  ((2, 2, 1), (0, 0, 0), (0, 0, 0), (0, 0, 0), 2),
  ((2, 3, 1), (0, 0, 0), (0, 0, 0), (0, 0, 0), 7),
  ((2, 3, 2), (0, 0, 0), (0, 0, 0), (0, 0, 0), 6),
  ((3, 4, 2), (0, 0, 0), (0, 0, 0), (0, 0, 0), 10),
)

#let labelled(code) = stack(
  dir: ttb,
  spacing: 2mm,
  goldstone(code),
  align(center, text(size: 8pt, kallay-label(code))),
)

= CCSDT singles diagrams

#grid(
  columns: (auto, auto, auto),
  gutter: 10mm,
  row-gutter: 8mm,
  align: center + horizon,
  ..diagrams.map(labelled),
)
