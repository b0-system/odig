Eqaf - Constant time equal function on `string`
-----------------------------------------------

From some crypto libraries like
[digestif](https://github.com/mirage/digestif.git) or
[Callipyge](https://github.com/oklm-wsh/Callipyge.git), it needed to have a
constant time equal function to avoid timing attacks. To avoid replication of
code and ensure maintainability of this kind of function, we decide to provide a
little package which implements `equal` function on `string`.

This library provides a benchmark to see if the equal function really has a
constant-time execution. We compare it with C implemention, Stdlib
implementation and some others impl. (like with `nativeint` or `int64`).

Benchmarks provides this kind of result:

```
- ########## Random ##########
- ---------- eqst ----------
- min:       0.002770.
- max:       0.150592.
- mean:      0.143873.
- median:    0.147260.
- deviation: 0.143137.
- deviation: 0.000206%.
- ---------- eqml ----------
- min:       0.000148.
- max:       0.000156.
- mean:      0.000153.
- median:    0.000153.
- deviation: 0.001563.
- deviation: 0.000000%.
- ########## Equal ##########
- ---------- eqst ----------
- min:       0.002805.
- max:       0.003014.
- mean:      0.002951.
- median:    0.002960.
- deviation: 0.006217.
- deviation: 0.000000%.
- ---------- eqml ----------
- min:       0.000152.
- max:       0.000158.
- mean:      0.000155.
- median:    0.000155.
- deviation: 0.001233.
- deviation: 0.000000%.
- ########## Total ##########
- ---------- eqst ----------
- min:       -0.000158.
- max:       0.147771.
- mean:      0.140922.
- median:    0.144310.
- deviation: 0.143125.
- deviation: 0.000202%.
- ---------- eqml ----------
- min:       -0.000009.
- max:       0.000003.
- mean:      -0.000003.
- median:    -0.000002.
- deviation: 0.001747.
- deviation: -0.000000%.
```

We run 2 benchmarks. Firsty, we see time needed to test `equal` on 2 random
`string`. In only one case, we will compare 2 equivalent `string` (by value, not
physically). This case highlights the difference on `eqst` on time executation.

Indeed, `eqst` (from Stdlib) is fast when it compare 2 differents `string` and
leaves up at the first byte which differ. So, when 2 `string` are equal, it will
take the biggest time:

```
- ---------- eqst ----------
- min:       0.002770.
- max:       0.150592.
```

You can see the minimum time on benchmarks and maximum times on `eqst` on random
inputs. But the most important result is the [standard
deviation](https://en.wikipedia.org/wiki/Standard_deviation):

```
- ---------- eqst ----------
- deviation: 0.000206%.
```

Which shows than some values on this benchmark are spread out compared on common
behavior (see `mean` value). This is exactly this context where we can do a
timing attack.

Then, we do the same benchmark on `eqml` and see the deviation:

```
- ---------- eqml ----------
- deviation: 0.000000%.
```

We launch then an other benchmark but on equal `string` and see, again, results.
In any case, we should have a standard deviation close to 0 %. Finally, compare
different `string` or equivalent `string` should take the same time. So a _diff_
betweem the first benchmark (different `string`) and the second (equivalent
`string`) should get a serie of 0 (or something close). We get same results and
see again standard deviation.

At the final step, we expect than standard deviation of `eqml` must be close to
0 %. If it's true, that means `eqml` takes the same time to compare any `string`
(if it's equal or not). Otherwise, we return an error.

Obviously, the final goal is to provide this kind of `equal` function so, of
course, tests works.

Happy hacking!
