#import "../lib.typ": _symmetric-attachments, _outer-open-assignments, _spread, _dn, _up, _th, goldstone
#import "../lib.typ": _minimal-arrow, _layout-clusters, _place-clusters, _interaction-crossings

#let placement(index, rank, center: 0.0) = (
  original-index: index,
  center: center,
  pair-xs: _spread(center, 0.64 * (rank - 1), rank),
)
#let port(group) = (group-index: group)
#let close(a, b) = assert(calc.abs(a - b) < 1e-9)

// A closed lens is vertical, even when its T bar has uncontracted pairs.
#let lens = _symmetric-attachments((placement(0, 2),),
  ((p: (port(0),), h: (port(0),)),), (_dn,))
#close(lens.group-x.first(), 0.32)
#assert(lens.placements.first().p-assignment.first().source-index == 1)
#assert(lens.placements.first().h-assignment.first().source-index == 1)

// Two closed lenses stay vertical and adjacent; the free V moves to the left.
#let loops = _symmetric-attachments((placement(0, 3),),
  ((p: (port(0), port(1)), h: (port(0), port(1))),), (_dn, _dn))
#close(loops.group-x.first(), 0.0)
#close(loops.group-x.last(), 0.64)
#for kind in ("p-assignment", "h-assignment") {
  assert(loops.placements.first().at(kind).map(it => it.source-index) == (1, 2))
}

// Prefer open pairs on the right when contractions lie to the left.
#let line(i, x) = (source-index: i, target: (x: x))
#let left-lines = (line(0, -0.96), line(2, -0.32))
#let right-open = _outer-open-assignments(_spread(0.0, 1.92, 4),
  left-lines, left-lines)
#for kind in ("p-assignment", "h-assignment") {
  assert(right-open.at(kind).map(it => it.source-index) == (0, 1))
}

// Moving a free pair preserves the order of closed and half-open sites.
#let mixed = _outer-open-assignments(_spread(0.0, 1.28, 3),
  (line(0, -0.64), line(2, 0.0)), (line(0, -0.64),))
#assert(mixed.p-assignment.map(it => it.source-index) == (0, 1))
#assert(mixed.h-assignment.first().source-index == 0)

// In 121 221 10, the T2 free pair faces away from T1, not into their gap.
// Check both spatial orientations without changing the logical port pairing.
#for direction in (-1, 1) {
  let multiple = _symmetric-attachments(
    (placement(0, 1, center: -0.60 * direction),
      placement(1, 2, center: 0.28 * direction)),
    ((p: (port(0),), h: (port(0),)),
      (p: (port(1),), h: (port(1),))), (_dn, _dn))
  let t2 = multiple.placements.at(1)
  let contracted = if direction == 1 { 0 } else { 1 }
  for kind in ("p-assignment", "h-assignment") {
    assert(t2.at(kind).first().source-index == contracted)
  }
  close(multiple.group-x.at(0), -0.60 * direction)
  close(multiple.group-x.at(1), -0.04 * direction)
}

// 110 232 10 and 111 231 10 have no fully open pair on T2. Leave the
// single open leg facing T1 and keep the closed lens on the outer T2 site.
#for swap in (false, true) {
  let targets = ((p: (port(0), port(1)), h: (port(0),)),
    (p: (), h: (port(1),)))
  if swap { targets = targets.map(target => (p: target.h, h: target.p)) }
  let half-open = _symmetric-attachments(
    (placement(0, 2, center: -0.28), placement(1, 1, center: 0.60)),
    targets, (_dn, _dn))
  close(half-open.group-x.at(0), -0.60)
  close(half-open.group-x.at(1), 0.32)
  let t2 = half-open.placements.first()
  for kind in ("p-assignment", "h-assignment") {
    assert(t2.at(kind).find(line => line.target.group-index == 0).source-index == 0)
  }
}

// Even an explicit outward preference cannot reorder singly open sites.
#for side in (-1, 1) {
  let particles = (line(0, -0.64), line(1, 0.0), line(2, 0.64))
  let holes = (line(1, 0.0),)
  let unchanged = _outer-open-assignments(_spread(0.0, 1.28, 3),
    particles, holes, open-side: side)
  assert(unchanged.p-assignment == particles)
  assert(unchanged.h-assignment == holes)
}

// In 220 222 10, H used to nearly touch the inner open legs. Move both
// endpoints outward equally, preserving source assignments and triangle sides.
#for offset in (0.04, 0.07, 0.12) {
  let clear = _symmetric-attachments(
    (placement(0, 2, center: -0.60), placement(1, 2, center: 0.60)),
    ((p: (), h: (port(0), port(1))),
      (p: (port(0), port(1)), h: ())), (_dn, _dn),
    through-offset: offset, clearance: 0.14)
  close(clear.group-x.first(), -(0.28 + offset + 0.14))
  close(clear.group-x.last(), -clear.group-x.first())
  for x in clear.group-x {
    for free in (-0.92 - offset, -0.28 - offset, 0.28 + offset, 0.92 + offset) {
      assert(calc.abs(x - free) >= 0.14 - 1e-9)
    }
  }
  for (i, kind) in ((0, "h-assignment"), (1, "p-assignment")) {
    let lines = clear.placements.at(i).at(kind)
    assert(lines.map(line => line.source-index) == (0, 1))
    for line in lines { close(line.target.x, clear.group-x.at(line.target.group-index)) }
  }
}

// Two separate T1 vertices form an isosceles triangle below one H endpoint.
#let triangle = _symmetric-attachments(
  (placement(0, 1, center: -0.28), placement(1, 1, center: 0.28)),
  ((p: (port(0),), h: ()), (p: (), h: (port(0),))), (_dn,))
#close(triangle.group-x.first(), 0.0)

// Through-lines lean inward equally at the two ends of a T2 bar.
#let through = _symmetric-attachments((placement(0, 2),),
  ((p: (), h: (port(0), port(1))),), (_th("h"), _th("h")),
  through-offset: 0.07)
#close(through.group-x.first(), -0.25)
#close(through.group-x.last(), 0.25)
#for line in through.placements.first().h-assignment {
  close(line.target.x, through.group-x.at(line.target.group-index))
}

// Preserve the conventional split H5 and symmetric bare interactions.
#let split = _symmetric-attachments((placement(0, 1),),
  ((p: (port(1),), h: (port(1),)),), (_up, _dn))
#close(split.group-x.first(), -0.52)
#close(split.group-x.last(), 0.0)
#assert(_symmetric-attachments((), (), (_up,)).group-x == (0.0,))
#let bare = _symmetric-attachments((), (), (_up, _up))
#close(bare.group-x.first(), -0.26)
#close(bare.group-x.last(), 0.26)

// H8/H9 put the upper-only endpoint on the side without an open T-leg crossing.
#for kind in ("p", "h") {
  let target = if kind == "p" { (p: (port(1),), h: ()) }
    else { (p: (), h: (port(1),)) }
  let upper = _symmetric-attachments((placement(0, 1),), (target,),
    (_up, _th(kind)), through-offset: 0.07)
  assert(_interaction-crossings(upper.placements, upper.group-x, 0.07) == 0)
  close(upper.group-x.at(0), if kind == "p" { 0.59 } else { -0.59 })

  // The short H–T segment wins over every external H leg, even for holes.
  let external = (from: (0, 0), to: (0, -1), tail: "h0", head: "e:h0", kind: "p")
  let internal = (from: (0, 1), to: (0, 0.4), tail: "t0:0", head: "h1", kind: kind)
  assert(_minimal-arrow((external, internal), 0.6) == (1,))
  assert(_minimal-arrow((external,), 0.6) == (0,))
  assert(_minimal-arrow((internal + (bend: 30deg),), 0.6) == ())
}

// 111 121 210 10: varying whole-bar order cuts three open-leg crossings to one.
#let items = (1, 2, 0).map(i =>
  (original-index: i, amplitude: (rank: if i == 2 { 2 } else { 1 })))
#let targets = ((p: (port(1),), h: ()),
  (p: (port(0),), h: (port(0),)), (p: (), h: (port(1),)))
#let seed = _symmetric-attachments(_place-clusters(items), targets, (_dn, _dn),
  through-offset: 0.07, clearance: 0.14)
#let optimized = _layout-clusters(items, targets, (_dn, _dn),
  through-offset: 0.07, clearance: 0.14)
#assert(_interaction-crossings(seed.placements, seed.group-x, 0.07) == 3)
#assert(_interaction-crossings(optimized.placements, optimized.group-x, 0.07) == 1)
#assert(optimized.placements.last().original-index == 1) // Closed T1 is rightmost.
#assert(calc.abs(optimized.group-x.at(1) - optimized.group-x.at(0)) >= 0.4)
#for item in optimized.placements {
  let assigned = item.p-assignment + item.h-assignment
  let expected = targets.at(item.original-index)
  assert(assigned.map(line => line.target.group-index).sorted()
    == (expected.p + expected.h).map(port => port.group-index).sorted())
}

// Exercise every interaction topology and non-default drawing proportions.
#set page(width: auto, height: auto, margin: 4mm)
#grid(columns: 4, gutter: 4mm,
  ..("111 0", "110 1", "221 2", "222 3", "220 4", "121 5",
    "232 6", "231 7", "111 8", "110 9", "342 10", "11", "12")
    .map(code => goldstone(code)),
  goldstone("220 4", spacing: 10mm, level-gap: 8mm, leg-angle: 30deg),
  goldstone("342 10", arrows: "all"),
  goldstone("111 121 210 10"),
  goldstone(((1, 2, 1), (2, 2, 1), (0, 0, 0), (0, 0, 0), 10)),
  goldstone("221 221 10"),
  goldstone(((2, 2, 0), (2, 2, 2), (0, 0, 0), (0, 0, 0), 10)),
  goldstone("220 222 10", spacing: 10mm, level-gap: 6mm, leg-angle: 30deg),
  goldstone(((1, 1, 0), (2, 3, 2), (0, 0, 0), (0, 0, 0), 10)),
  goldstone(((1, 1, 1), (2, 3, 1), (0, 0, 0), (0, 0, 0), 10)),
)
