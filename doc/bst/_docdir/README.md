# bisec-tree

Bisector tree implementation in OCaml.

A bisector tree allows to do fast and exact nearest neighbor searches
in any space provided that you have a metric (function) to measure the
distance between any two points in that space.

Cf. this article for details:
"A Data Structure and an Algorithm for the Nearest Point Problem";
Iraj Kalaranti and Gerard McDonald.
ieeexplore.ieee.org/iel5/32/35936/01703102.pdf

![Bunny](data/stanford_bunny.png?raw=true)

Figure: the Stanford bunny, consisting of 35947 3D points, guillotined
by the first layer of a bisector tree.
