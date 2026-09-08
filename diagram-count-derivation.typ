// Build: typst compile diagram-count-derivation.typ
// Arkheion is an arXiv-style template, not an official AIP production template.
// AUTHOR ACTIONS BEFORE SUBMISSION:
// - Replace author/affiliation/contact placeholders and complete declarations.
// - Review all scientific statements and the proposed Table 1 sign corrections.
// - Archive the accompanying code/tests and insert the permanent identifier.
// - Check current JCP file-format, disclosure, and submission requirements.
// - Disclose AI assistance as required by the journal; AI is not an author.
#import "@preview/arkheion:0.1.2": arkheion

#set page(paper: "us-letter")
#set text(size: 11pt)
#set par(leading: 0.65em)
#show: arkheion.with(
  title: "Combinatorial enumeration of coupled-cluster and extended coupled-cluster diagrams",
  authors: ((name: "[Author name(s)]",),),
  custom-authors: align(center)[
    #v(0.6em)
    *[Author name(s)]* \
    [Department, institution, city, postal code, country] \
    [Corresponding author email]
  ],
  abstract: [
    Connected antisymmetrized diagram counts provide consistency checks for
    automatically generated coupled-cluster equations and operators. We
    restate the representation and construction algorithm of Kállay and
    Surján and derive equation counts from a multiset generating function.
    Five contraction polynomials suffice for a one- and two-body Hamiltonian.
    Their complete-equation sum has denominator $(1-x)^4(1+x)^2$, explaining
    the cubic growth and parity dependence of the counts previously obtained
    by Musiał, Kucharski, and Bartlett. Low-rank and finite-truncation
    corrections follow directly. Allowing external annihilation lines gives
    a quartic polynomial for the full similarity-transformed Hamiltonian;
    exact enumeration validates both results through cluster rank 20.
    We then extend the construction to a second similarity transformation
    by a pure deexcitation operator. Particle–hole incidence rows record each
    deexcitation vertex's connections to the Hamiltonian and to individual
    excitation vertices. Unique representatives require quotienting both row
    permutations and residual permutations of equivalent excitation vertices.
    The latter group has order at most four for the present Hamiltonian.
    This yields an explicit finite
    construction algorithm and a Burnside-averaged generating function for
    independent counting checks. The two successive connectivity conditions
    for the literal double similarity transform are distinguished from the
    stronger doubly-linked restriction on the energy in canonical extended
    coupled-cluster amplitude coordinates. Small-truncation enumerations
    validate the incidence construction and illustrate its increased
    combinatorial complexity. All counts concern generic, unfactorized
    antisymmetrized topologies, not labelled Wick contractions or algebraic weights.
  ],
)

// Single-column review manuscript: numbered equations, Roman main sections,
// captioned tables, and numerical AIP-style references.
#set text(hyphenate: true)
#set par(justify: true, first-line-indent: 1em)
#set heading(numbering: (..ns) => {
  let v = ns.pos()
  if v.len() == 1 { numbering("I.", v.first()) }
  else if v.len() == 2 { numbering("A.", v.last()) }
  else { numbering("1.", v.last()) }
})
#set math.equation(numbering: "(1)")
#show ref: it => {
  let el = it.element
  if el != none and el.func() == math.equation {
    link(el.location())[Eq.~#numbering("(1)", ..counter(math.equation).at(el.location()))]
  } else { it }
}
#show heading: set text(hyphenate: false)
#show raw: set text(size: 0.9em)
#show bibliography: set text(size: 10pt)
#show bibliography: set par(first-line-indent: 0pt, leading: 0.4em)
#set cite(style: "american-institute-of-physics")
#set figure.caption(position: top)
#show figure.where(kind: table): set figure(numbering: "I")
#set table(stroke: none, inset: (x: 6pt, y: 4pt))

= Introduction

Automatic generation of coupled-cluster (CC) equations separates the
combinatorial task of identifying connected contractions from their algebraic
interpretation and numerical implementation. The compact representation of
Kállay and Surján associates each antisymmetrized diagram with a Hamiltonian
vertex and a canonical collection of cluster-vertex descriptors.@kallay2001
An independently obtained diagram count is a useful check on this
construction: it can detect missing or duplicated topologies without
requiring a comparison of their algebraic expressions.

The projected-equation counting problem has already been solved for the
electronic one- and two-body Hamiltonian. Musiał, Kucharski, and Bartlett derived
cubic, parity-dependent formulas for both antisymmetrized and Goldstone
diagrams and distinguished a fully retained equation at a specified CC
truncation from a complete equation that no longer changes on increasing
that truncation.@musial2002 Their Table 1 gives the counts for three
successive truncations relative to the equation rank. The present work does
not propose a new count in place of those results. Its purpose is to derive
the antisymmetrized count from a single multiset generating function and to
make its connection to the canonical representation explicit.

The relevant mathematical tools are the ordinary generating functions for
unlabelled multisets,@flajolet2009 rational-function coefficient
extraction,@wilf1994 and the characterization of quasipolynomials by poles at
roots of unity.@stanley2012 These tools explain why the count is cubic,
why even and odd equation ranks differ, and why a finite number of initial
values require separate corrections. They also permit a direct treatment of
the correlation-energy equation and of the bare Hamiltonian terms that are
excluded from some published diagram counts. We further distinguish the
projected equations from the full similarity-transformed operator: the latter
retains terms that annihilate the reference but contribute when acting on
excited states. Counting these terms requires relaxing the contraction
constraints, not summing only the CC equations retained at a given truncation.

In extended coupled cluster (ECC), an additional exponential of a pure
deexcitation operator introduces contractions between distinct cluster
families. The resulting topology is no longer determined by a multiset of
one-vertex contraction totals. We retain the original Hamiltonian–excitation
subgraph and add an incidence matrix for the deexcitation vertices. This
extension also requires distinguishing ordinary graph canonicalization from
the canonical *amplitude coordinates* of ECC, whose energy obeys a stronger
doubly-linked restriction.@kvaal2020

= Counting conventions and canonical diagrams

== Hamiltonian and equation ranks

Let the Hamiltonian, normal ordered with respect to a single-determinant
reference $Phi_0$, be written as

$ H = E_("ref") + H_("N"), quad H_("N") = F_("N") + W_("N"),
  quad T = sum_(e=1)^n T_e. $ <eq-hamiltonian>

Here $F_("N")$ and $W_("N")$ are the normal-ordered one- and two-body
operators, and $n$ is the maximum cluster excitation rank. The equation
rank is $k$, with $0 <= k <= n$. We count the connected antisymmetrized
topologies contributing to

$ R_k = lr(⟨ Phi_k | (H_("N") exp T)_("c") | Phi_0 ⟩). $ <eq-residual>

Here $Phi_k$ denotes a generic $k$-fold excited determinant. For $k=0$, the
quantity is the correlation energy, not the scalar reference energy.
For $k>0$, it is the corresponding projected residual before setting it to
zero. The subscript c restricts the expansion to connected contributions.

The Hamiltonian is generic: no Hartree–Fock zeros, additional orbital
symmetries, spin integration, or finite orbital-space restrictions are
imposed. All thirteen Hamiltonian vertices of Fig. 1 in
Ref. #cite(<kallay2001>, form: "normal") are retained. In particular, the
bare one- and two-body excitation vertices are included in the singles and
doubles equations. Each antisymmetrized topology is counted once, regardless
of its algebraic sign, symmetry factor, or number of external-index
permutations. This convention corresponds to the *non-HF antisymmetrized*
column of Ref. #cite(<musial2002>, form: "normal"), rather than to its
separate Goldstone-diagram column. The count is not an operation count for
an implementation using intermediates.

== The Kállay–Surján integer string and tuple representation

Equation (8) and Sec. II A of Kállay and Surján (pp. 2947–2948) encode each
diagram as a string of thirteen integers.@kallay2001 Grouping the first
twelve integers into triplets gives the equivalent tuple-of-tuples form

$ D = ((epsilon_1,iota_1,pi_1), (epsilon_2,iota_2,pi_2),
       (epsilon_3,iota_3,pi_3), (epsilon_4,iota_4,pi_4), eta). $ <eq-tuple>

The final integer $eta in {0,1,dots,12}$ selects the Hamiltonian vertex.
Each active triplet describes one cluster vertex: $epsilon_j$ is its
excitation rank, $iota_j$ is the number of lines contracted with the
Hamiltonian, and $pi_j$ is the number of these that are particle lines.
Thus the internal hole count is $iota_j-pi_j$, and the cluster's external
particle and hole counts are $epsilon_j-pi_j$ and
$epsilon_j-iota_j+pi_j$, respectively. At most four cluster vertices occur;
unused positions are padded on the right by $(0,0,0)$. Padding does not
represent a rank-zero cluster operator.

Active triplets are lexicographically nondecreasing: excitation rank is
ordered first, then internal-line count within equal ranks, then particle-line
count within equal ranks and internal-line counts. Only the active triplets
are ordered; the zero padding is appended afterwards. For example,

#align(center)[`((2, 2, 1), (0, 0, 0), (0, 0, 0), (0, 0, 0), 5)`]

contains a single $T_2$ joined by one particle and one hole line to vertex
$eta=5$. The latter also supplies one external particle and one external
hole, so this is a doubles-equation diagram. In contrast,

#align(center)[`((2, 4, 2), (0, 0, 0), (0, 0, 0), (0, 0, 0), 10)`]

has all four $T_2$ lines contracted with the deexcitation vertex and
contributes to the correlation energy. Repeated identical *active* triplets
are permitted and denote separate equivalent cluster vertices. The string
records topology and line species, not orbital labels or the diagram weight.

== A multiset representation

Represent a cluster vertex by $(e,p,h)$, where $e$ is its excitation rank
and $p$ and $h$ are the numbers of particle and hole lines contracted with
the Hamiltonian. An admissible connected vertex satisfies

$ 1 <= e <= n, quad 0 <= p,h <= e, quad p+h >= 1. $ <eq-admissibility>

The equivalent descriptor in the Kállay–Surján representation is
$(epsilon,iota,pi)=(e,p+h,p)$. Excitation operators do not contract with
one another in this construction; each cluster vertex is attached directly
to the Hamiltonian. Since the latter has at most four incident lines, at
most four cluster vertices can occur.

Permuting cluster vertices does not produce a new canonical diagram.
Sorting their descriptors gives a unique representative of a multiset,
i.e., an unordered collection allowing repetitions. Conversely, a multiset
satisfying the contraction constraints, together with its Hamiltonian
vertex, determines the canonical descriptor. Thus there is a bijection
between these multisets and the diagram objects counted here. The
multiplicity of equivalent Wick contractions belongs to the diagram's
weight, not to the number of canonical objects.

For a Hamiltonian vertex, write $(P,H;P_0,H_0)$ for its internal and
external particle–hole line totals. The symbol $H$ in this tuple is a hole
count, not the Hamiltonian operator. Conservation of lines requires

$ sum_j p_j = P, quad sum_j h_j = H, quad
  P_0 + sum_j (e_j-p_j) = H_0 + sum_j (e_j-h_j) = k. $ <eq-lines>

Consequently, the total cluster rank $m$ is fixed by

$ m = sum_j e_j = k+P-P_0 = k+H-H_0. $ <eq-rank-shift>

For the Hamiltonian in @eq-hamiltonian, $P,H<=2$ and $m<=k+2$.
These small contraction bounds are what make a closed evaluation possible.

== Explicit construction of the projected-equation diagrams

The following restates the algorithm of Sec. II A, p. 2948, of
Ref. #cite(<kallay2001>, form: "normal"), using the notation above and
making the connectedness and canonical-order tests explicit.

+ *Choose cluster ranks.* For each integer
  $m=max(0,k-2),dots,k+2$, enumerate partitions
  $m=e_1+dots+e_l$ with $0<=l<=4$ and
  $1<=e_1<=dots<=e_l<=n$. The empty partition has $m=0$.
+ *Choose the Hamiltonian vertex.* For each $eta$, retain the rank partition
  only when $P_0+m-P=H_0+m-H=k$ and the Hamiltonian has enough lower
  lines to attach all $l$ clusters. The thirteen choices and their line
  totals are listed in @tab-vertices.
+ *Distribute internal lines.* Partition the $P+H$ lower Hamiltonian lines
  into $l$ positive group sizes $iota_j$ and permute those sizes over the
  chosen cluster ranks. Reject $iota_j>2e_j$.
+ *Assign particle and hole species.* Assign $P$ particle markers (ones)
  and $H$ hole markers (zeros) to those groups. Permutations inside an
  individual group are equivalent and are represented only once. The number
  of ones in group $j$ is $pi_j$. Retain only
  $0<=pi_j<=e_j$ and $0<=iota_j-pi_j<=e_j$.
+ *Canonicalize and emit.* Retain lexicographically ordered active triplets,
  append zero padding and $eta$, and output each canonical tuple once.
  With no clusters, the line constraints permit only the appropriate bare
  excitation vertex. There is no bare scalar reference-energy diagram.

The implementation in `generate_equation` uses an equivalent, less redundant
version of the two line-distribution steps. For a fixed rank partition and
Hamiltonian vertex it enumerates bounded compositions directly,

$ (p_1,dots,p_l) in {bold(p): sum_j p_j=P, 0<=p_j<=e_j}, $
$ (h_1,dots,h_l) in {bold(h): sum_j h_j=H, 0<=h_j<=e_j}, $ <eq-compositions>

and forms $(e_j,p_j+h_j,p_j)$, rejecting $p_j+h_j=0$. This avoids
constructing permutations of individual binary line markers. Every valid
diagram supplies one of the enumerated rank partitions and line assignments,
so the construction is exhaustive. The hierarchical ordering eliminates
permutations of indistinguishable cluster vertices, so the canonical output
is unique. No sign or symmetry-factor calculation is needed merely to list
the topologies.

= Multiset generating functions

== The multivariate construction

Let $x$ mark the total cluster rank and let $u$ and $v$ mark internal
particle and hole contractions. The ordinary generating function for the
admissible cluster multisets is

$ cal(M)_n (x,u,v) = product_(e=1)^n
  product_(0<=p,h<=min(e,2) \ p+h>=1)
  (1-x^e u^p v^h)^(-1). $ <eq-multiset>

Each factor is a geometric series whose exponent records how many times
one vertex type occurs. This is the standard product construction for
unlabelled multisets, as described in Sec. I.2 of
Ref. #cite(<flajolet2009>, form: "normal"). Restricting $p,h$ to two
loses no diagram because the Hamiltonian cannot supply more contractions
of either kind. Define

$ A_(P H)^n (x) = [u^P v^H] cal(M)_n (x,u,v). $ <eq-A-definition>

The notation $[x^j]$ denotes coefficient extraction, with coefficients of
negative powers taken as zero for an ordinary polynomial. We have
$A_00^(n)=1$, and particle–hole reflection gives
$A_(P H)^(n)=A_(H P)^(n)$. Only five nonempty contraction totals need to
be evaluated: $(1,0)$, $(2,0)$, $(1,1)$, $(2,1)$, and $(2,2)$.

== Explicit contraction polynomials

#block(breakable: false)[
Introduce the rank polynomials

$ E_n (x) = sum_(e=1)^n x^e, quad B_n (x) = sum_(e=2)^n x^e, $ <eq-E-B>
]

where an empty sum is zero. A contraction type requiring rank at least one
contributes $E_n$; a type requiring rank at least two contributes $B_n$.
For two copies of the same contraction type with minimum rank one, the
ranks form an unordered pair and contribute

$ Q_n (x) = sum_(1<=a<=b<=n) x^(a+b)
  = (E_n (x)^2+E_n (x^2))/2. $ <eq-Q>

The product $E_n (x)^2$ counts ordered pairs. Pairs with different ranks
occur twice, whereas equal-rank pairs occur once; the added diagonal term
$E_n (x^2)$ therefore makes division by two exact. This is the two-element
multiset construction of Sec. I.6.1 in
Ref. #cite(<flajolet2009>, form: "normal"), not a division by a diagram
symmetry factor.

Suppressing the superscript $n$ on $A$ and writing $E=E_n$, $B=B_n$,
and $Q=Q_n$, direct coefficient extraction from @eq-multiset gives

$ A_10 &= E, \
  A_20 &= B+Q, \
  A_11 &= E+E^2, \
  A_21 &= B+B E+E^2+Q E, \
  A_22 &= B+2E B+B^2+Q+2B Q+E^3+Q^2. $ <eq-A-explicit>

For example, the four terms of $A_21$ correspond to the partitions of the
contraction vector

$ (2,1), quad (2,0)+(0,1), quad (1,1)+(1,0), quad
  (1,0)+(1,0)+(0,1). $ <eq-partitions-21>

In the last case the two $(1,0)$ vertices form an unordered pair, which
explains the factor $Q$. Similarly, the nine vector partitions of $(2,2)$
give the seven grouped terms in $A_22$. The terms $2E B$ and $2B Q$ each
combine a pair of particle–hole reflections; $Q$ counts two $(1,1)$
vertices; and $Q^2$ counts two $(1,0)$ vertices and two $(0,1)$ vertices.
This reduction avoids any sum over four-element excitation-rank partitions.

== Summation over Hamiltonian vertices

#figure(
  table(
    columns: (auto, auto, auto, auto),
    align: center,
    table.hline(stroke: 0.7pt),
    table.header([$eta$], [$(P,H;P_0,H_0)$], [Polynomial], [Extract]),
    table.hline(stroke: 0.4pt),
    [$0,1$], [$(1,0;1,0)$ and reflection], [$2A_10$], [$[x^k]$],
    [$2$], [$(1,1;0,0)$], [$A_11$], [$[x^(k+1)]$],
    [$3,4$], [$(2,0;2,0)$ and reflection], [$2A_20$], [$[x^k]$],
    [$5$], [$(1,1;1,1)$], [$A_11$], [$[x^k]$],
    [$6,7$], [$(2,1;1,0)$ and reflection], [$2A_21$], [$[x^(k+1)]$],
    [$8,9$], [$(1,0;2,1)$ and reflection], [$2A_10$], [$[x^(k-1)]$],
    [$10$], [$(2,2;0,0)$], [$A_22$], [$[x^(k+2)]$],
    [$11$], [$(0,0;1,1)$], [$1$], [$[x^(k-1)]$],
    [$12$], [$(0,0;2,2)$], [$1$], [$[x^(k-2)]$],
    table.hline(stroke: 0.7pt),
  ),
  caption: [Hamiltonian contraction totals and coefficient shifts. The
    labels $eta$ follow Fig. 1 of Kállay and Surján.@kallay2001 Reflected
    vertices remain distinct diagrams and are included by the factor two.],
) <tab-vertices>

Using @eq-rank-shift, the thirteen Hamiltonian vertices contribute as
listed in @tab-vertices. Their sum is the rank-generating polynomial

$ G_n (x) &= 2A_10+2A_20+A_11+x^(-1)A_11+2x^(-1)A_21 \
  &quad +2x A_10+x^(-2)A_22+x+x^2, $ <eq-G-finite>

and the desired count is

$ N(n,k) = [x^k]G_n (x), quad 0<=k<=n. $ <eq-count-coefficient>

Although @eq-G-finite uses negative powers to express the coefficient
shifts, the polynomials multiplying them start at sufficiently high degree
that $G_n$ has no negative powers. The terms $x+x^2$ are the bare
excitation vertices. There is no bare constant term because $E_("ref")$
is excluded. Together, @eq-A-explicit and @eq-G-finite constitute a finite,
non-enumerative coefficient formula for the canonical count.

= Complete equations and eventual quasipolynomiality

== Rational generating function

Since every diagram in the rank-$k$ equation has total cluster rank at most
$k+2$, no individual cluster rank can exceed that bound. Thus the equation
is complete once $n>=k+2$, in agreement with
Ref. #cite(<musial2002>, form: "normal"). Denote its count by $S(k)$.
For a fixed coefficient, the finite rank polynomials may then be replaced
by their formal power-series limits,

$ E(x)=x/(1-x), quad B(x)=x^2/(1-x), quad
  Q(x)=x^2/((1-x)(1-x^2)). $ <eq-stable-building-blocks>

Substitution into @eq-A-explicit and @eq-G-finite yields

$ cal(S)(x) = sum_(k>=0)S(k)x^k
  = (3+9x+5x^2-25x^3-8x^4+21x^5-5x^7+x^8)
    /((1-x)^4(1+x)^2). $ <eq-stable-GF>

The generating function is interpreted formally; no analytic convergence
assumption is needed to extract its coefficients. Partial fractions give

$ cal(S)(x) &= x^2-3x-5-11/(4(1-x))+103/(16(1-x)^2) \
  &quad +11/(4(1-x)^3)+1/(4(1-x)^4)
  +5/(4(1+x))+1/(16(1+x)^2). $ <eq-partial-fractions>

The coefficient identity

$ [x^k](1-alpha x)^(-r) = alpha^k binom(k+r-1,r-1) $ <eq-coefficient-identity>

then evaluates each term directly. This is the rational-function method
illustrated in Secs. 1.2 and 3.15 of
Ref. #cite(<wilf1994>, form: "normal").

== Parity and the initial coefficients

A quasipolynomial is a function that agrees with one polynomial on each
residue class modulo a fixed positive integer. Equivalently, it is a
polynomial whose coefficients are periodic functions of the integer
argument. A sequence is *eventually* quasipolynomial if this property holds
after finitely many initial values. Proposition 4.4.1 of
Ref. #cite(<stanley2012>, form: "normal") characterizes quasipolynomials
through proper rational generating functions whose poles are roots of
unity. A polynomial part in an improper rational function changes only
finitely many coefficients, giving the corresponding eventual statement.

In @eq-stable-GF the numerator is nonzero at both $x=1$ and $x=-1$.
The pole at $1$ has order four and therefore contributes a polynomial of
degree three. The pole at $-1$ has order two and contributes $(-1)^k$
times a polynomial of degree one. Hence the eventual quasipolynomial has
degree three and minimal quasiperiod two. The parity effect has a concrete
combinatorial origin: the equal-rank pairs in @eq-Q introduce the factor
$(1-x^2)^(-1)$.

Define

$ U(k) = (2k^3+78k^2+529k+321+(3k+63)(-1)^k)/48. $ <eq-U>

The complete-equation count, including every nonnegative rank, is

$ S(k) = U(k)-5delta_(k,0)-3delta_(k,1)+delta_(k,2), $ <eq-S-unified>

where $delta_(i,j)$ is the Kronecker delta. These finite-support corrections
are exactly the coefficients of $-5-3x+x^2$ in @eq-partial-fractions.
In particular, $S(0)=3$, $S(1)=15$, and $S(2)=38$, whereas $U$ alone
would give $8$, $18$, and $37$. For $k>=3$, the parity branches are

$ S(k)=cases(
  display((k^3+39k^2+266k+192)/24) & quad k " even",
  display((k^3+39k^2+263k+129)/24) & quad k " odd".
) $ <eq-parity>

Thus the sequence is not a quasipolynomial at all nonnegative ranks without
corrections. Its leading growth is $S(k)~k^3/24$, and the alternating
contribution is only linear in $k$.

= Finite-truncation boundary corrections

Only the cases $n=k$ and $n=k+1$ differ from the complete equation.
For $n=k+1$, a removed cluster vertex must have rank $k+2$. The total-rank
bound forces it to be the sole cluster vertex. There is exactly one such
diagram: the $(2,2)$ contraction type in $A_22$ attached to Hamiltonian
vertex $eta=10$. Consequently $N(k+1,k)=S(k)-1$, including $k=0$.

For $n=k>=1$, six additional diagrams contain a vertex of rank $k+1$.
Three have a single cluster vertex: one comes from $x^(-1)A_11$ and two
from $2x^(-1)A_21$. The remaining three have total rank $k+2$ and two
cluster vertices, of ranks $k+1$ and $1$. They are the two reflected
$E B$ contributions and the unordered-pair contribution $Q$ within
$x^(-2)A_22$. These six objects are distinct, and no others can be
removed because the total rank cannot exceed $k+2$. Together with the
rank-$(k+2)$ diagram, they give a correction of seven.

For $n=k=0$, there are no cluster vertices. All three complete-equation
correlation-energy diagrams disappear, and the excluded scalar reference
energy cannot supply a replacement. The complete result is therefore

$ N(n,k)=cases(
  0 & quad n=k=0,
  S(k)-7 & quad n=k>=1,
  S(k)-1 & quad n=k+1,
  S(k) & quad n>=k+2,
), quad 0<=k<=n, $ <eq-final-count>

with $S$ given by @eq-S-unified. The energy counts are $0$, $2$, and
$3$ at truncations $n=0$, $n=1$, and $n>=2$, respectively. The stable
three topologies are the one-body contraction with $T_1$, the two-body
contraction with $T_2$, and the two-body contraction with $T_1^2$.

= The full similarity-transformed Hamiltonian

== Operator diagrams versus projected equations

For a pure excitation cluster operator, the connected-cluster identity gives

$ overline(H)_("N") = exp(-T) H_("N") exp(T)
  = (H_("N") exp T)_("c"). $ <eq-hbar>

This is Eq. (6) of Kállay and Surján, p. 2946.@kallay2001 The expression
on the right is understood as a Wick expansion with only connected terms
retained; it is not an instruction to contract every Hamiltonian annihilation
line. The nested-commutator expansion terminates after four commutators for
the present Hamiltonian, equivalently permitting at most four attached
cluster vertices. Here we count the expanded, reference-normal-ordered
operator before introducing intermediates, combining dressed tensors, or
using solved CC equations to set residuals to zero.

The earlier equation count includes only diagrams that survive the action
of $overline(H)_("N")$ on $Phi_0$, and then only the selected excitation
rank. The full operator also contains external annihilation lines. They
annihilate the reference but can act nontrivially on excited states. Thus
summing $N(n,k)$ for $0<=k<=n$ cannot count the full operator. Even summing
all pure-excitation ranks would omit its annihilation sectors.

Here creation and annihilation refer to *quasiparticles relative to the
reference*: particle creation creates an electron in a virtual orbital,
whereas hole creation removes an electron from an occupied orbital. In the
Hamiltonian tuple $(P,H;P_0,H_0)$, $P,H$ count the available lower
quasiparticle-annihilation lines and $P_0,H_0$ count the upper
quasiparticle-creation lines. In the projected equations every lower line is
internal; in the full operator an unused lower line remains external.

== The same tuple determines every external line

Let an active cluster multiset have total rank $m$ and contracted particle
and hole totals $s$ and $t$. The full-operator admissibility conditions are

$ s=sum_j p_j<=P, quad t=sum_j h_j<=H, quad p_j+h_j>=1. $ <eq-partial-contractions>

The per-vertex rank bounds are unchanged. Replacing the two equalities in
@eq-lines by these inequalities is the essential generalization. The
external signature, in the order created particles, created holes,
annihilated particles, annihilated holes, is

$ (c_p,c_h,a_p,a_h)
  = (P_0+m-s, H_0+m-t, P-s, H-t). $ <eq-signature>

All four numbers follow from the existing triplets and $eta$; no extra
tuple fields are required. Equivalent choices of which individual
Hamiltonian lines of the same species are contracted affect the algebraic
weight, not the unlabelled antisymmetrized topology. If explicit external
orbital labels or permutation-resolved Wick contractions were wanted,
additional information would be necessary, but those are different counting
conventions. Kállay and Surján already note on p. 2948 that the integer
strings can describe intermediates as well as final equation diagrams.

For example, the tuple

#align(center)[`((2, 1, 1), (0, 0, 0), (0, 0, 0), (0, 0, 0), 10)`]

now represents a valid operator diagram. It has a single particle
contraction from $T_2$ to the two-body deexcitation vertex and signature
$(1,2,1,2)$. It is a three-body operator contribution and vanishes when
acting directly on the reference. It is excluded by the projected-equation
algorithm, which would demand two particle and two hole contractions.

Electron-number conservation implies

$ g=c_p-a_p=c_h-a_h=m+P_0-P=m+H_0-H. $ <eq-grade>

The integer $g$ is the net excitation grade and need not be nonnegative.
The usual operator body rank is
$r=(c_p+c_h+a_p+a_h)/2=g+a_p+a_h$. The signature of a projected
rank-$k$ diagram is exactly $(k,k,0,0)$.

A direct enumeration of the full operator is therefore simple. For each
Hamiltonian vertex, form all connected cluster types
$(e,p+h,p)$ with $1<=e<=n$, $p<=min(e,P)$, and $h<=min(e,H)$.
Starting with the empty tuple and remaining capacities $(P,H)$, recursively
append nondecreasing cluster types that fit the remaining capacities.
Subtract their particle and hole counts and emit every visited state,
including the empty state, with the usual padding and Hamiltonian label.
Each appended type consumes at least one lower line, so the recursion has
depth at most four. No rank-$k$ projection filter is applied. This is the
procedure implemented by `generate_similarity_transformed`.

== Sector-resolved generating function

The same multiset polynomials $A_(s t)^n$ enumerate these diagrams.
Let $x$ mark the net excitation grade and let $y,z$ mark external particle
and hole annihilation counts. The finite Laurent polynomial

$ cal(B)_n (x,y,z)=sum_(eta=0)^12 x^(P_0-P)
  sum_(s=0)^P sum_(t=0)^H y^(P-s) z^(H-t) A_(s t)^n (x) $ <eq-operator-GF>

contains every operator topology once; the four Hamiltonian line totals
in each summand are those of vertex $eta$. The coefficient of
$x^g y^(a_p) z^(a_h)$ counts the external signature
$(g+a_p,g+a_h,a_p,a_h)$. Negative powers of $x$ accommodate deexcitation
sectors. The pure-creation part is precisely the earlier polynomial,

$ [y^0 z^0]cal(B)_n (x,y,z)=G_n (x). $ <eq-operator-projection>

This identity also clarifies why $G_n$ contains coefficients at equation
ranks beyond the retained CC equations: it describes the entire action on
the reference, not only the residuals with $k<=n$. For instance, for
singles–doubles truncation,

$ G_2 (x)=3+14x+31x^2+22x^3+13x^4+4x^5+x^6. $ <eq-CCSD-pure>

Only its first three coefficients enter the CCSD energy and amplitude
equations. The sum of all seven coefficients is 88, still smaller than the
full operator count derived below.

== Total count and annihilation sectors

Set all three markers to one in @eq-operator-GF. Summing over the
Hamiltonian capacities gives

$ C(n)=cal(B)_n (1,1,1)
  = 13+16A_10+6A_20+5A_11+4A_21+A_22, $ <eq-operator-total-A>

where all $A$ are now evaluated at $x=1$. The constant 13 counts every
bare Hamiltonian vertex, not a scalar reference energy. For $n>=1$,

$ E_n (1)=n, quad B_n (1)=n-1, quad Q_n (1)=n(n+1)/2. $ <eq-operator-building-blocks>

Substitution into @eq-A-explicit gives the closed result

$ C(n)=cases(
  13 & quad n=0,
  display((n^4+18n^3+87n^2+106n+12)/4) & quad n>=1.
) $ <eq-operator-total>

Unlike the fixed-equation-rank count, this is an eventual *polynomial*,
not a parity-dependent quasipolynomial. Summing over all allowed cluster
ranks turns the unordered-pair factor into $n(n+1)/2$. The leading
$n^4/4$ term arises from $Q_n (1)^2$, describing two particle-only and
two hole-only cluster vertices attached to $eta=10$.
The exceptional value at zero follows from $B_0=0$, not $n-1$.
At zero truncation the operator is simply $H_("N")$, with all thirteen
vertices. At positive truncation, the generated correlation-energy scalar
is included, while the original scalar $E_("ref")$ remains excluded.

More detail is obtained by summing only over $g$. Define

$ C_(a_p,a_h) (n)=[y^(a_p)z^(a_h)]cal(B)_n (1,y,z). $ <eq-sector-count>

The six sector classes under particle–hole reflection are listed in
@tab-sectors. The two members of a reflected pair are distinct
sectors with the same count, not a single combined entry. Their multiplicities
therefore give

$ C(n)=C_(0,0) (n)+2C_(1,0) (n)+2C_(2,0) (n)
             +C_(1,1) (n)+2C_(2,1) (n)+C_(2,2) (n). $ <eq-sector-sum>

#figure(
  table(
    columns: (auto, auto, auto),
    align: center,
    table.hline(stroke: 0.7pt),
    table.header([$(a_p,a_h)$], [Count per sector, $n>=1$], [$n=2$]),
    table.hline(stroke: 0.4pt),
    [$(0,0)$], [$(n^4+14n^3+47n^2+22n-8)/4$], [88],
    [$(1,0)$, $(0,1)$], [$(n^3+8n^2+11n)/2$], [31],
    [$(2,0)$, $(0,2)$], [$(n^2+5n)/2$], [7],
    [$(1,1)$], [$(n+1)(n+2)$], [12],
    [$(2,1)$, $(1,2)$], [$n+1$], [3],
    [$(2,2)$], [$1$], [1],
    table.hline(stroke: 0.7pt),
  ),
  caption: [Expanded operator counts resolved by external quasiparticle
    annihilation counts and summed over all net excitation grades. At $n=2$,
    the total is $88+2(31)+2(7)+12+2(3)+1=183$.],
) <tab-sectors>

For example, the $(1,0)$ sector is
$2+3E+A_11+A_20+A_21$, and the $(0,0)$ sector is
$2+4A_10+2A_20+2A_11+2A_21+A_22$, all at $x=1$.
These expressions, together with @eq-A-explicit, directly give the first
two rows of @tab-sectors. The remaining sectors are
$1+E+A_20$, $2+2E+A_11$, $1+E$, and $1$, respectively.
They also apply at $n=0$ when the finite-polynomial values $E=B=Q=0$
are used rather than the positive-$n$ polynomial continuations.

For reference, the totals at truncations $n=0,1,2,3,4,5$ are
$13,56,183,420,809,1398$. These are counts of expanded topologies across
all operator body ranks. At $n>=1$ the maximum body rank is $4n-2$:
a bare $b$-body vertex with $c$ contractions has body rank $b+m-c$;
connectedness gives $m<=c n$, and $c<=2b<=4$.
The bound is attained by four $T_n$ vertices singly attached to the
two-body deexcitation vertex. It is consistent with the fact that a
singles-only similarity transformation does not increase the two-body rank.
Counting only a specified body-rank block, an EOM matrix element, or a
factorized intermediate representation would be a different enumeration.

= Extension to extended coupled cluster

== Two successive connectivity conditions

Use a single, common truncation rank $n$ for the excitation and
deexcitation operators, retaining all amplitudes of ranks $1,dots,n$:

$ T=sum_(e=1)^n T_e, quad S=sum_(r=1)^n S_r, quad
  cal(K)=exp(S)exp(-T)H_("N")exp(T)exp(-S). $ <eq-ECC-operator>

Each $S_r$ contains $r$ particle and $r$ hole quasiparticle annihilators.
The common cutoff does not identify the two sets of amplitudes:
$S$ and $T$ are independent, and no adjoint relation is assumed. Normal order the inner transform first. Since a pure annihilation
operator $S$ placed on the right of a normal-ordered term cannot contract
with it, the final $exp(-S)$ cancels the outer $S$ vertices that have no
contraction with that term. Thus

$ cal(K)=[exp(S)(H_("N")exp(T))_(C_T)]_(C_S), $ <eq-ECC-connected>

where $C_T$ requires every $T$ to touch $H_("N")$ directly, and $C_S$
requires every $S$ to touch at least one creation line of the resulting
Hamiltonian–$T$ subgraph. This also follows by applying the connected
commutator argument separately to the two similarity transformations.
Permitted contractions are $H$–$T$, $H$–$S$, and $T$–$S$; there are
no $T$–$T$ or $S$–$S$ contractions. An $H$–$S$ contraction uses an
*upper creation line* of $H$, whereas an $H$–$T$ contraction uses a
*lower annihilation line*. Every $T$ still needs its own direct connection
to $H$: mere connectedness of the final graph would incorrectly admit
$T$ vertices linked to $H$ only through an $S$ vertex.

== Original and canonical amplitude coordinates

The original, or noncanonical, ECC coordinates are the independent
amplitudes $(T,S)$. They parameterize a right state $exp(T)Phi_0$ and a
left state represented by the bra $"⟨" Phi_0 "|" exp(S)exp(-T)$.
Their overlap is one, since

$ lr(⟨Phi_0|exp(S)exp(-T)exp(T)|Phi_0⟩)=1. $

This is a bivariational parameterization, not a requirement that the bra
be the Hermitian adjoint of the ket. Its energy is

$ E_("NC") (T,S)=lr(⟨Phi_0|exp(S)exp(-T)H_("N")exp(T)|Phi_0⟩). $ <eq-ECC-NC-energy>

Here “NC” means noncanonical ECC, not ordinary CC with a linear left
parameterization $1+Lambda$: the full exponential $exp(S)$ is retained.
In particular, the literal double transform of @eq-ECC-operator uses these
original coordinates. Its two successive connectivity conditions must be
distinguished from the stronger doubly-linked energy theorem below.

Define a new pure excitation operator $Sigma$, leaving the deexcitation
operator $S$ unchanged, by

$ Sigma Phi_0=Q exp(S)T Phi_0, quad
  T Phi_0=Q exp(-S)Sigma Phi_0, quad
  Q=1-"|" Phi_0 "⟩⟨" Phi_0 "|". $ <eq-ECC-coordinates>

The projector removes the reference component; $Sigma$ and $T$ have no
scalar amplitudes. These maps are inverses because $exp(S)Phi_0=exp(-S)Phi_0=Phi_0$.
They are linear in the excitation amplitudes at fixed $S$, but nonlinear
as transformations of the joint amplitude coordinates. This is the map
in Sec. III A, Eqs. (11)–(14), p. 5 of
#link("https://arxiv.org/abs/2003.06796")[arXiv:2003.06796],@kvaal2020 with
$Sigma$ denoting that reference's $T'$ and with the deexcitation operator
written directly as $S$.

The canonical-coordinate energy is the same scalar functional expressed
in the new variables:

$ E_("C") (Sigma,S)=E_("NC") (T(Sigma,S),S). $ <eq-ECC-pullback>

Its diagrammatic simplification is

$ E_("C") (Sigma,S)
  =lr(⟨Phi_0|exp(S)exp(-Sigma)H_("N")exp(Sigma)|Phi_0⟩)_("DL"), $ <eq-ECC-C-energy>

where every $S$ vertex must touch $H$ or at least *two distinct* $Sigma$
vertices. Terms in which an $S$ is attached only to a single excitation
vertex are absorbed into the coordinate map. The negative terms in the
inverse map cancel those single-source attachments in the energy
expansion. They are not neglected contributions to an approximate energy.
Consequently, @eq-ECC-C-energy is generally *not*
$E_("NC") (Sigma,S)$ evaluated with the same numerical amplitudes.
It equals the original energy at the *mapped* amplitudes $T(Sigma,S),S$.
Nor does the energy theorem license filtering the full literal operator
$cal(K)(Sigma,S)$ in the same way: an operator expressed in canonical
coordinates is first obtained by substituting $T(Sigma,S)$.

=== Why these coordinates are called canonical

The word refers to the Hamiltonian structure of the time-dependent
bivariational equations, not to canonical Hartree–Fock orbitals or to
sorting integer tuples. In dual excitation/deexcitation bases, write the
amplitudes of $Sigma,S$ as $sigma_mu,s_mu$. The kinetic one-form of the
bivariational action obeys

$ theta=lr(⟨Phi_0|exp(S) d T|Phi_0⟩)
  =d f-sum_mu sigma_mu d s_mu, quad
  f=lr(⟨Phi_0|exp(S)T|Phi_0⟩). $ <eq-ECC-one-form>

This follows by differentiating $f$, using commutativity of the pure
deexcitation operators and @eq-ECC-coordinates. Up to an exact
differential, it is the canonical one-form $sum_mu s_mu d sigma_mu$.
With $"ℏ"=1$, the corresponding equations have the canonical form

$ i (d sigma_mu)/(d t)=(partial E_("C"))/(partial s_mu), quad
  -i (d s_mu)/(d t)=(partial E_("C"))/(partial sigma_mu). $ <eq-ECC-Hamilton-equations>

The original amplitudes $T,S$ generally do not give this simple canonical
pairing. Ordinary graph canonicalization, used below to choose a unique
representative, is unrelated to this symplectic meaning of “canonical.”

=== Equivalence at a common rank-complete truncation

A deexcitation acting on a rank-$e$ excited state can only lower its
excitation rank. Therefore both maps in @eq-ECC-coordinates preserve the
space containing *all* excitation amplitudes of ranks $1,dots,n$.
The map is triangular in rank with identity diagonal: $Sigma_n=T_n$, and
only higher-rank $T$ amplitudes can contribute to $Sigma_k-T_k$.
The unchanged $S$ retains the same cutoff. Thus the original and canonical
formulations at this common, rank-complete truncation are two invertibly
related coordinate descriptions of the *same* truncated ECC model, not
two different correlation approximations. The corresponding result is
Theorem 5 in Sec. III D, p. 7 of the same arXiv version.@kvaal2020 Their stationary solutions map into one another and have
the same energy. Algebraically, the stationary equations are related by
an invertible Jacobian, although their written diagram expansions differ.

For ECC singles–doubles, the entire coordinate transformation reduces to

$ Sigma_2=T_2, quad
  Sigma_1=T_1+(S_1 T_2)_("exc",1), $ <eq-ECC-SD-forward>
$ T_2=Sigma_2, quad
  T_1=Sigma_1-(S_1 Sigma_2)_("exc",1). $ <eq-ECC-SD-inverse>

Here $(S_1 T_2)_("exc",1)$ is the pure rank-one excitation operator whose
action on $Phi_0$ is the rank-one part of $S_1 T_2 Phi_0$; the $S_1$
annihilators are fully contracted. Contributions from $S_2 T_2$ or
$S_1^2 T_2$ are scalars and are removed by $Q$. This makes the reduction
of energy diagrams transparent: single-source $S_1$–$T_2$ attachments
are incorporated into $Sigma_1$. An energy $S_2$ cannot attach only to
one $T_e$ with $e<=2$, since that $T_e$ must already use at least one
line to touch $H$. More generally, a fully contracted $S_r$ attached
only to one $T_e$ requires $e>r$. At singles-only truncation there are no
such attachments, the coordinate map is the identity, and the two energy
counts agree.

Rank completeness matters. Additional selected-excitation or orbital-space
restrictions need not be closed under the rank-lowering coordinate map;
then equivalence must be checked separately. Equality of just the two
maximum ranks is not by itself a proof for such restricted models. In the
generic rank-complete convention used here, the reduction from 1503 to
907 ECCSD energy topologies reflects a change of coordinates, not a change
in the stationary energy. The construction below uses $T$ to name its
excitation-vertex slots; for the canonical-coordinate energy those slots
are interpreted as $Sigma$ vertices.

== An incidence extension of the integer string

Retain an ordinary canonical operator tuple $D_T$, with $l<=4$ active
$T$ vertices, as the Hamiltonian–$T$ subgraph. Its triplets remain
$(e_j,p_j+h_j,p_j)$, but these internal-line counts now mean specifically
*$H$–$T$ contractions*, not all internal lines incident on $T^((j))$ in
the final ECC graph. The available creation-line capacities at sources
$j=0,1,dots,l$ are

$ (gamma_0^p,gamma_0^h)=(P_0,H_0), quad
  (gamma_j^p,gamma_j^h)=(e_j-p_j,e_j-h_j) " for " j>=1. $ <eq-ECC-capacities>

Source zero is $H$, and sources $1,dots,l$ are the active $T$ vertices
in their canonical order. Describe $S$ vertex $a$ by its rank $r_a$ and
one pair of edge counts per source,

$ omega_a=(r_a,(b_(a 0),b_(a 1),dots,b_(a l))), quad
  b_(a j)=(u_(a j),v_(a j)). $ <eq-ECC-row>

The entries count particle and hole contractions from source $j$ to this
$S$ vertex. The full representation is the nested tuple

$ D_("ECC")=(D_T,(omega_1,dots,omega_q)). $ <eq-ECC-tuple>

No individual orbital labels are introduced. The original zero padding of
$D_T$ is retained, but the $S$ tuple is variable length and has no padding.
The necessary and sufficient incidence constraints are

$ 1<=r_a<=n, quad u_(a j),v_(a j) in ZZ_(>=0), $
$ sum_j u_(a j)<=r_a, quad sum_j v_(a j)<=r_a, quad
  sum_j (u_(a j)+v_(a j))>=1, $ <eq-ECC-row-bounds>
$ sum_a u_(a j)<=gamma_j^p, quad
  sum_a v_(a j)<=gamma_j^h. $ <eq-ECC-column-bounds>

The first two row inequalities are the rank bounds; the last enforces the
outer connectedness condition. The column inequalities prohibit using a
source line twice. Along with the validity of $D_T$, these conditions
construct an admissible species-coloured contraction multigraph. All
remaining lines are external. Selecting individual indistinguishable lines
within a species changes Wick multiplicities and symmetry factors, not
the topology counted here.

Adding only an $S$ triplet $(r_a,iota_a,pi_a)$ would lose essential
information: its entries give row totals but not the destinations of the
edges. For a concrete counterexample, take

#align(center)[`D_T = ((2, 2, 1), (2, 2, 1), (0, 0, 0), (0, 0, 0), 10)`]

and two $S_1$ vertices. Both $T_2$ vertices have one remaining particle
and one remaining hole. Two inequivalent incidence matrices, with columns
$H,T^((1)),T^((2))$ labelling the two rank-two vertices, are

$ B_A=mat((0,0),(1,1),(0,0); (0,0),(0,0),(1,1)), quad
  B_B=mat((0,0),(1,0),(0,1); (0,0),(0,1),(1,0)). $ <eq-ECC-counterexample>

In $B_A$, each $S_1$ closes the remaining pair on a single $T_2$.
In $B_B$, each $S_1$ connects the particle from one $T_2$ to the hole
from the other. Both have the same original $T$ triplets, the same
$S$ triplets $(1,2,1)$, and even the same particle–hole degree at every
vertex. Nevertheless, they are different scalar topologies. Both belong
to the literal ECC energy; only $B_B$ satisfies the stronger
canonical-coordinate doubly-linked condition.

== External signature, termination, and energy projection

Write the inner operator signature as $(C_p,C_h,A_p,A_h)$ and define

$ R_S=sum_a r_a, quad U=sum_(a,j) u_(a j), quad V=sum_(a,j) v_(a j). $

The final signature is

$ (c_p,c_h,a_p,a_h)
  =(C_p-U,C_h-V,A_p+R_S-U,A_h+R_S-V). $ <eq-ECC-signature>

In particular, its excitation grade is $g=g_T-R_S$, where
$g_T=C_p-A_p=C_h-A_h$. This recovers a rank-selection rule analogous to
@eq-rank-shift: for a fixed target signature the total $S$ rank is fixed,
$R_S=g_T-g$. Its required particle and hole contraction totals are
$U=C_p-c_p$ and $V=C_h-c_h$. Negative values rule out that subgraph.
The two annihilation-count equations in @eq-ECC-signature must also hold.

There is a finite construction at a fixed common cutoff $n$, but there is
*no four-vertex bound on $S$*. Each $S$ consumes at least one available
creation line, so, for $n>=1$,

$ q<=C_p+C_h<=8n-4, quad R_S<=n(C_p+C_h). $ <eq-ECC-termination>

To see the creation-line bound, a bare $b$-body vertex with $L$ lower lines,
$c$ contractions to $T$, and total attached rank $m$ has
$C_p+C_h=2b-L+2m-c$. Use $m<=c n$, $c<=L<=2b$, and $b<=2$.
At $n=2$, twelve singly attached $S_1$ vertices are possible in the full
operator. Thus a common *rank* cutoff does not truncate either exponential
at order $n$ or impose four padded slots on both cluster families.
At $n=0$ there are no cluster vertices and $cal(K)=H_("N")$.

The ECC energy is the scalar projection

$ E_("ECC")=lr(⟨Phi_0|cal(K)|Phi_0⟩)
  =lr(⟨Phi_0|exp(S)exp(-T)H_("N")exp(T)|Phi_0⟩). $ <eq-ECC-energy>

Since $R_S-U>=0$ and $R_S-V>=0$, a scalar requires
$A_p=A_h=0$, $C_p=C_h=R_S$, and every $S$ row fully contracted,

$ sum_j u_(a j)=sum_j v_(a j)=r_a, quad
  sum_a u_(a j)=gamma_j^p, quad sum_a v_(a j)=gamma_j^h. $ <eq-ECC-energy-bounds>

These equalities greatly reduce the energy enumeration. With
$R_T=sum_j e_j$, the common-truncation energy problem can be organized
by pairs of rank partitions satisfying

$ 1<=e_j,r_a<=n, quad
  R_T-R_S=P-P_0=H-H_0, quad abs(R_T-R_S)<=2. $ <eq-ECC-energy-ranks>

In addition, $R_S=C_p=C_h<=4n-2$ for $n>=1$, so the energy has at most
$4n-2$ deexcitation vertices. Sharing a cutoff does *not* require
$R_T=R_S$: the Hamiltonian supplies their grade difference. It also does
not allow us to discard inner pure-excitation ranks above $n$, since they
can be closed by several $S$ vertices. The incidence data and residual
column-permutation quotient remain necessary. For the canonical-coordinate
energy only, add the row test

$ u_(a 0)+v_(a 0)>0 " or "
  abs({j>=1: u_(a j)+v_(a j)>0})>=2. $ <eq-ECC-DL>

Two lines attached to the *same* $T$ do not meet the second alternative.
No statement here identifies this filtered energy with the full operator
in untransformed $T,S$ coordinates.

== Unique representatives and an explicit construction algorithm

For a fixed labelled $D_T$, sort the $S$ rows lexicographically. This
quotients permutations of equivalent deexcitation vertices, but is not yet
sufficient: two identical $T$ triplets can exchange their entire incidence
columns. Let

$ Gamma_(D_T)={rho in frak(S)_l:
  (e_(rho(j)),p_(rho(j)),h_(rho(j)))=(e_j,p_j,h_j) " for all " j}. $ <eq-ECC-group>

Equivalently, $Gamma_(D_T)$ is the direct product of permutation groups
on the multiplicity classes of equal $T$ triplets. The four slots give the
crude order bound $4! = 24$, but the present line capacities sharpen it to
$abs(Gamma_(D_T))<=4$. Every connected type consumes at least one particle
or hole line, so no type can occur more than twice when $P,H<=2$.
At most two multiplicity-two classes occur, giving $2! dot 2! = 4$.
The bound is attained by two particle-only and two hole-only triplets
attached to vertex $eta=10$. Keep the Hamiltonian column fixed. For every $rho$ in this
group, permute the $T$ columns simultaneously in all $S$ rows, sort the
rows, and select the lexicographically smallest row tuple. Together with
$D_T$ this is the unique ECC representative. Permutations of unlike $T$
triplets have already been removed by canonicalizing the inner subgraph;
particle and hole colours and the $T$ and $S$ vertex families are never
interchanged.

The resulting extension of the Kállay–Surján construction is:

+ Generate each canonical inner operator tuple $D_T$ using the
  partial-contraction algorithm of the preceding section, not just the retained
  projected CC equations. Compute its source capacities.
+ Form every candidate $S$ row of rank $1,dots,n$ satisfying the row
  bounds and the individual source capacities. For energy diagrams, impose
  full row contraction at this stage and discard inner annihilation sectors.
+ Starting from the empty row tuple, recursively append nondecreasing
  candidate rows that fit the remaining source capacities. Subtract their
  edge counts column by column. Emit every visited state for the full
  operator; emit only states exhausting the capacities for the energy.
  Reusing a row is permitted and represents another identical $S$ vertex.
+ Canonicalize each emitted state under $Gamma_(D_T)$, sorting its rows
  after each column permutation, and retain each representative once.
+ Apply any requested external-signature filter using @eq-ECC-signature.
  For a preselected signature one can instead enumerate nondecreasing
  $S$ ranks summing to $g_T-g$ and distribute the required $U,V$ by
  bounded incidence matrices, directly paralleling the rank-partition and
  line-distribution steps of the original algorithm. Apply @eq-ECC-DL
  only when the canonical-coordinate energy is requested.

This construction is exhaustive because deleting all $S$ vertices from
any valid diagram recovers one generated inner subgraph, and its remaining
edges determine an allowed multiset of rows. It is unique because any
isomorphism between two such diagrams restricts to an automorphism of
that fixed inner subgraph, namely an element of $Gamma_(D_T)$, together
with a permutation of $S$ rows. Conversely, each of those permutations
preserves the represented topology. Testing at most four admissible column permutations
therefore suffices; a factorial search over all $S$ vertex permutations
is unnecessary. The number of distinct output diagrams can nevertheless
be very large.

If the desired objects are ECC *stationarity equations* rather than
operator sectors, start with the appropriate scalar energy graphs and
mark a vertex of the amplitude rank being differentiated. Canonicalize with
that vertex distinguished; removing it exposes the residual indices.
Equivalent choices of the marked vertex supply derivative multiplicities,
not additional unique residual topologies. This applies separately to
variations of $S$ and $T$ (or $S,Sigma$ in canonical coordinates). Simply
filtering annihilation and creation sectors of the literal transformed
operator should not be identified with both families of ECC stationarity
equations without the corresponding variation argument.

== Counting without listing graph representatives

There is a useful independent check on the orbit enumeration. For a fixed
inner tuple, let $cal(R)$ be the finite set of allowed $S$ row types and
associate with a row $omega$ the monomial

$ w(omega)=z^(r_omega) product_(j=0)^l x_j^(u_(omega j)) y_j^(v_(omega j)). $ <eq-ECC-weight>

An ordinary multiset product $product_(omega in cal(R)) (1-w(omega))^(-1)$
counts rows with *labelled source columns*. It overcounts whenever
$Gamma_(D_T)$ has nontrivial orbits; dividing that count by the group order
is also incorrect because stabilizers vary. For $rho in Gamma_(D_T)$,
a fixed multiset must contain every row in a $rho$-orbit with equal
multiplicity. Its generating function is therefore

$ F_rho=product_(O in cal(R) "/" lr(⟨rho⟩))
  (1-product_(omega in O) w(omega))^(-1). $ <eq-ECC-fixed-GF>

Here the product runs over row-type orbits under the cyclic subgroup
generated by $rho$, not over its cycles on individual source columns.
Truncate source degrees to $gamma_j^p,gamma_j^h$. For each retained term,
$z$ records $R_S$, while the sums of the $x$ and $y$ degrees give $U,V$.
Classifying by @eq-ECC-signature gives fixed-diagram counts in each external
sector. Burnside's lemma then gives the number of inequivalent diagrams
for that sector as the average over $rho$. Source capacities are constant
on equivalent $T$ columns, so this truncation and sector selection are
invariant under the group. Summing the averages over all inner tuples
counts the complete ECC operator. Energy counts follow by using fully
contracted row types and retaining exactly the source capacities; the
stronger energy condition can also be imposed directly on $cal(R)$.

This is a finite coefficient algorithm, not a quartic closed form analogous
to @eq-operator-total. Its extra orbit structure is precisely the information
lost by an attempted extension using only cluster triplets and total line
counts.

== Implementation and small-truncation checks

The unified `generate_kallay.py` implements the CC, full single-transform,
and ECC constructions, including the incidence tuples and explicit algorithm. `generate_ecc(n)` returns the literal full operator
with a common cutoff for both cluster families; `ecc_external_signature`
returns its four external line counts. `generate_ecc_energy(n)` closes all lines, and its optional
`canonical_coordinates=True` selects the stronger energy theorem, with
the amplitude interpretation described above. The default equation CLI and
CC tuple format are unchanged; additional `--mode` choices select `hbar`,
`ecc`, or `ecc-energy`. The canonical-coordinate option is restricted to the
last mode. JSON arrays from these modes can be read directly by Typst.

The accompanying `lib.typ` now renders partially contracted operators and
nested ECC tuples as well as equation diagrams. The extended layout uses
explicit creation/annihilation ports, preserves every incidence entry, and
leaves unused ports as short external stubs. $T$ vertices lie below $H$ and
$S$ vertices above it; $H$ is displaced sideways when necessary to keep
$T$–$S$ edges away from its vertices. The original equation layout remains
the default for undecorated, fully contracted Hamiltonian annihilation sectors.
Rendering applies neither an energy-connectivity filter nor a coordinate
transformation. Tests reconstruct the incidence matrices and signatures from
the actual rendering segments for all 183 rank-two single-transform tuples,
all 395 singles-only ECC operator tuples, and all 1503 original-coordinate
ECCSD energy tuples. Additional checks exercise malformed inputs and a
twelve-$S$-vertex diagram.

#figure(
  table(
    columns: 4,
    align: center,
    table.hline(stroke: 0.7pt),
    table.header([$n$], [Full operator], [Energy, original], [Energy, canonical]),
    table.hline(stroke: 0.4pt),
    [0], [13], [0], [0],
    [1], [395], [20], [20],
    [2], [8,743,171#super[∗]], [1,503], [907],
    table.hline(stroke: 0.7pt),
  ),
  caption: [ECC topology counts at a common rank-complete truncation $n$
    for excitation and deexcitation amplitudes. “Canonical” refers to amplitude coordinates, not to graph
    labelling. All bare $H_("N")$ vertices are retained, and the reference
    scalar is excluded. The starred full-operator count is obtained by
    Burnside coefficient counting only, without listing its millions of
    representatives. All other entries were also explicitly enumerated.],
) <tab-ECC-counts>

The test file `tests/test_generate_ecc.py` independently implements
@eq-ECC-fixed-GF and the Burnside average. Full-operator counts resolved by
both inner tuple and external signature agree with explicit enumeration
at common cutoffs $n=0,1$. Both energy variants agree with the orbit-product
counts at $n=2$. Additional checks cover row and column relabellings and
the incidence examples. Unequal-cutoff helper functions are retained
privately for diagnostic checks only: switching off either cluster family
recovers a single similarity transformation, and an additional asymmetric
case checks larger graphs against explicit enumeration. These are not
additional members of the common-truncation ECC hierarchy presented here.
The full $n=2$ count illustrates why the explicit generator is intended
as a small-truncation reference implementation rather than a scalable way
to store all ECC operators. None of these checks evaluates signs, symmetry
factors, or numerical ECC energies.

= Published counts and numerical verification

== Relation to Musiał, Kucharski, and Bartlett

The variable $n$ in Table 1 of Ref. #cite(<musial2002>, form: "normal")
denotes the equation rank, not the CC truncation. In the notation used here,
their three models therefore correspond to $n=k$, $n=k+1$, and $n=k+2$.
Their auxiliary polynomial for antisymmetrized diagrams is

$ N_a (k)=k^3/24+13k^2/8+133k/12+1. $ <eq-Na>

For $k>=3$, our formulas imply

$ S(k)=cases(
  N_a (k)+7 & quad k " even",
  N_a (k)+9/2-(k+1)/8 & quad k " odd".
) $ <eq-published-comparison>

Together with @eq-final-count, this gives @tab-comparison. The base-model
formula and the six-then-one increase on adding higher clusters coincide
with the counts and discussion of Ref. #cite(<musial2002>, form: "normal").

#figure(
  table(
    columns: (auto, auto, auto, auto),
    align: center,
    table.hline(stroke: 0.7pt),
    table.header([Truncation], [$k$ even], [$k$ odd], [Unified form]),
    table.hline(stroke: 0.4pt),
    [$n=k$], [$N_a$], [$N_a-5/2-(k+1)/8$], [$S(k)-7$],
    [$n=k+1$], [$N_a+6$], [$N_a+7/2-(k+1)/8$], [$S(k)-1$],
    [$n>=k+2$], [$N_a+7$], [$N_a+9/2-(k+1)/8$], [$S(k)$],
    table.hline(stroke: 0.7pt),
  ),
  caption: [Non-HF antisymmetrized counts for $k>=3$, expressed using
    the auxiliary polynomial of Musiał et al.@musial2002 The two
    positive half-integer terms in the higher-truncation odd-rank rows
    correct apparent sign errors in the printed table; see the text.],
) <tab-comparison>

A literal comparison requires noting two apparent typographical errors.
The printed non-HF antisymmetrized odd-rank entries for truncations
$k+1$ and $k+2$ contain $-7/2$ and $-9/2$, respectively, in place of
$+7/2$ and $+9/2$. The printed signs would make the count decrease by
one upon each enlargement of the cluster space, contrary both to the
inclusion of diagram sets and to the increments of six and one stated in
Sec. 2 of that paper. For example, at $k=3$ the printed entries give
$46$ and $45$, while direct enumeration and @eq-final-count give $53$
and $54$, following the base count $47$. The corrected signs in
@tab-comparison reconcile these statements. No claim about corrections to
the separate HF or Goldstone columns is needed here.

There is also a genuine convention difference at low rank. Table 1 of
Ref. #cite(<musial2002>, form: "normal") explicitly omits the constant
term in the doubles equation. This term is the bare excitation integral,
not the scalar reference energy. Because it is retained here, our doubles
counts $(31,37,38)$ at truncations $(2,3,4)$ exceed their counts
$(30,36,37)$ by one. Their Table 1 is restricted to equation ranks above
one. In Table 4, the non-HF CCS singles count similarly omits its bare
one-body excitation term and is seven rather than eight. These differences
are independent of the exclusion of $E_("ref")$ in @eq-hamiltonian.

== Reproducible enumeration checks

The closed form and the finite generating polynomials were checked against
`generate_equation(n, k)` in the accompanying Python implementation of the
Kállay–Surján construction. Every pair $0<=k<=n<=20$ was tested, giving
231 distinct truncation–equation comparisons. The checks also compare
the contribution of each of the thirteen Hamiltonian vertices, rather than
only their sum. In addition, coefficients through degree 80 obtained from
the multiset polynomials were checked against both @eq-stable-GF and
@eq-partial-fractions. All comparisons use exact integer or rational
arithmetic. The accompanying regression test
`tests/test_diagram_count_derivation.py` records these checks; no numerical
fit is used in the derivation. The positive-rank values also agree with
Table I of Kállay and Surján, p. 2948, which uses the same bare-vertex
convention as the present generator.@kallay2001

The full-operator implementation was independently checked for every
$n=0,dots,20$ by directly multiplying the multivariate geometric factors
in @eq-multiset, retaining particle and hole degrees through two. Applying
@eq-operator-GF to those coefficients gives the expected count for each
Hamiltonian label and complete external signature. These counts agree with
explicit tuple enumeration, @eq-operator-total, and @tab-sectors. Filtering
the operator tuples to signature $(k,k,0,0)$ recovers the original equation
generator's exact tuples for all 231 pairs, not merely their counts.
`tests/test_similarity_transformed.py` records these comparisons, the
maximum-body-rank check, and the explicit tuple examples. The formula can
be evaluated without enumeration using `count_similarity_transformed(n)`;
`external_signature` returns the four line counts of a valid tuple.

#figure(
  table(
    columns: 8,
    align: center,
    table.hline(stroke: 0.7pt),
    table.header([$n$], [$k=0$], [$k=1$], [$k=2$], [$k=3$], [$k=4$], [$k=5$], [$k=6$]),
    table.hline(stroke: 0.4pt),
    [$0$], [0], [—], [—], [—], [—], [—], [—],
    [$1$], [2], [8], [—], [—], [—], [—], [—],
    [$2$], [3], [14], [31], [—], [—], [—], [—],
    [$3$], [3], [15], [37], [47], [—], [—], [—],
    [$4$], [3], [15], [38], [53], [74], [—], [—],
    [$5$], [3], [15], [38], [54], [80], [99], [—],
    [$6$], [3], [15], [38], [54], [81], [105], [135],
    table.hline(stroke: 0.7pt),
  ),
  caption: [Canonical connected antisymmetrized counts $N(n,k)$. Bare
    singles and doubles vertices are included, and the scalar reference
    energy is excluded. Dashes denote ranks outside $0<=k<=n$.],
) <tab-counts>

Representative values are given in @tab-counts. Evaluating
@eq-S-unified and @eq-final-count requires a fixed number of arithmetic
operations and no diagram enumeration. This is a constant arithmetic-operation
count, not a claim of constant bit complexity for arbitrarily large
integer inputs. Agreement of total counts is a useful regression check,
but it does not by itself validate the algebraic weights of the diagrams.

= Conclusions

The canonical antisymmetrized diagrams of a one- and two-body CC
Hamiltonian can be counted as multisets of cluster vertices subject to
small particle–hole contraction totals. This representation reduces the
problem to five explicit polynomials and a finite sum over Hamiltonian
vertices. Their complete-equation generating function explains the known
cubic, parity-dependent count through poles at $1$ and $-1$. Its
polynomial part supplies the low-rank corrections, while the maximum total
cluster rank gives the finite-truncation corrections directly.

The result provides an alternative combinatorial derivation of the
non-HF antisymmetrized formulas of Musiał et al., rather than a new
replacement for those formulas. It also identifies precisely which
bare-vertex conventions must be reconciled when using published counts to
validate an automatic diagram generator.

The same representation also counts the full similarity-transformed
Hamiltonian. Allowing uncontracted Hamiltonian annihilation lines leaves
the tuple format unchanged because the remaining external lines are
inferable from it. A sector-resolved generating function then gives the
quartic total count and recovers all projected equations as its
annihilation-free part. Thus cubic parity dependence at fixed equation rank
and quartic polynomial growth of the full operator have a common multiset
origin, but concern different counting problems and different rank variables.
For a second similarity transformation by a pure deexcitation operator,
the required additional information is the particle–hole incidence of each
new cluster with the existing subgraph. Multisets of these incidence rows,
quotiented by the residual permutations of at most four excitation vertices,
provide a unique representation and an exhaustive construction. A separate
Burnside coefficient calculation validates the small-truncation counts.
The distinction between the literal double transform and the stronger
canonical-coordinate ECC energy theorem is essential: imposing the latter
restriction indiscriminately would discard valid operator topologies.
No simple polynomial total for general ECC truncations is claimed here.

Extending the Hamiltonian beyond two-body rank would require more cluster
slots and additional contraction polynomials and larger permutation groups.
The generating-function and incidence constructions remain starting points,
but the degree, period, and group-size bounds obtained here rely on the
present Hamiltonian and the specified pure excitation/deexcitation operators.

#heading(numbering: none)[Acknowledgments]

[Author action: supply acknowledgments and funding information, or remove
this section if it is not applicable.]

#heading(numbering: none)[Author declarations]

#heading(level: 2, numbering: none)[Conflict of interest]
[Author action: supply the authors' conflict-of-interest declaration.]

#heading(level: 2, numbering: none)[Author contributions]
[Author action: supply the authors' contributions using the journal's
requested contributor-role format.]

#heading(numbering: none)[Data availability]

The integer counts reported here can be reproduced from the equations in
this article and the Python generator and regression tests accompanying the
manuscript source. [Author action: deposit these files in a persistent
public archive and add its identifier before submission.]

// Keep the reference list together on its own manuscript page.
#pagebreak()
#bibliography(
  "diagram-count-derivation.bib",
  style: "american-institute-of-physics",
  title: [References],
)
