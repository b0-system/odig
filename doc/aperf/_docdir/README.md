# aperf — OCaml tools for loop perforation

# Examples

## k-means

k-means has two loops that can be perforated

1. the loop over the points when finding new centers
1. the number of iterations of the step algorithm

I have trained the automatic perforation over 10 input sets, each of
100,000 2-dimensional points with each dimension in the range [0,50].

For a baseline, here are the exhaustive results where we try all
combinations of loop perforations between 0 and 100% by steps of 5%:

![](exhaustive.training.png)

And here are the results for the automatic perforation:

![](training.data.png)

Each trained perforation was then tested on a different set of live data:
10 input sets, each of 1,000,000 2-dimensional points with each
dimension in the range [0,50].

![](live.data.png)

Below is a combined graph where the trained results are in red and the
live results are in blue.
The green points are the additional configurations which the live data
set discovered.
Green lines are when accuracy increased for a configuration from the
training run to the live run and a red line is when accuracy
decreased.

![](combined.png)
