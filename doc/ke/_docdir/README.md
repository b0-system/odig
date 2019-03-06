Ke - Fast implementation of Queue in OCaml
==========================================

![travis-ci](https://travis-ci.org/mirage/ke.svg?banch=master)

Queue or FIFO is one of the most famous data-structure used in several
algorithms. `Ke` provides some implementations of it in a functionnal or
imperative way.

It is a little library with benchmark
([`bechamel`](https://github.com/dinosaure/bechamel.git) or `core_bench`),
fuzzer and tests.

From what we know, `Ke.Rke` is the faster implementation than `Queue` from the
standard library or the `base` package. It is limited by some kind of data (see
[`Bigarray.kind`]()) but enough for a large amount of algorithms. The fast
operation is to put some elements faster than a sequence of `Queue.push`, and
get some elements faster than a sequence of `Queue.pop`.

Then we provide a functionnal interface `Fke` or an imperative interface `Rke`.

We extended implementations to have a limit of elements to store (see
`Rke.Weighted` and `Fke.Weigted`). The purpose of it is to limit memory
consumption of queue when we use it in some contexts (like _encoder_).

Again, as a part of the MirageOS project, `Ke` does not rely on C stubs,
`Obj.magic` and so on.

Author: Romain Calascibetta <romain.calascibetta@gmail.com>

Documentation: https://mirage.github.io/ke/

Notes about Implementations
===========================

The functionnal implementation `Fke` is come from the Okazaki's queue
implementation with GADT to discard impossible case.

`Rke`, `Rke.Weighted` and `Fke.Weighted` was limited by kind and follow Xen's
implementation of the shared memory ring-buffer. Length of the internal buffer
is, in any case, a power of two - that means, in some context, for a large
amount of elements, this kind of queue does not fit on your request.

Fuzzer was made to compare the standard Queue (as an oracle) with `Rke` and
`Fke`. We construct a set of actions (`push` and `pop`) and ensure (by GADT) to
never `pop` an empty queue.
