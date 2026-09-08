#import "../lib.typ": goldstone, kallay-label, parse-kallay

#let full = parse-kallay("220 000 000 000 4")
#let short = parse-kallay("220 4")
#assert(full.interaction == 4)
#assert(full.amplitudes.first() == (2, 2, 0))
#assert(short.amplitudes == ((2, 2, 0),))
#assert(parse-kallay("10/2/1 5").amplitudes.first() == (10, 2, 1))
#assert(parse-kallay(((2, 2, 0), 4)).interaction == 4)
#assert(parse-kallay("12").amplitudes == ())

#set page(width: auto, height: auto, margin: 4mm)
#grid(
  columns: (auto, auto),
  gutter: 5mm,
  row-gutter: 5mm,
  goldstone("220 4"),
  goldstone("111 220 7"),
  goldstone("111 111 220 10"),
  goldstone("220 222 10"),
  goldstone("11"),
  goldstone("12"),
  goldstone("111 0"),
  kallay-label("111 220 000 000 7"),
  goldstone("111 121 6", arrows: "all"),
  goldstone("111 121 6", loop-bend: 30deg),
  goldstone("110 121 311 10", labels: true),
)
