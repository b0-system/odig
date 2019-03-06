# vp-tree
A vantage point tree implementation in OCaml.

Cf. http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.41.4193&rep=rep1&type=pdf
for details.

A vantage point tree allows to do fast but exact nearest neighbor searches
in any space provided that you have a distance function
to measure the distance between any two points in that space.

This implementation might need some tweaks in case it is used to index a very
large number of points (especially the select_vp function in the code).
