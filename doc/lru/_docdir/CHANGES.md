## v0.2.0 2017-03-31

Breaking changes:

* `resize` no longer drops bindings if the new size pushes the queue over capacity.

* `of_list` has simpler semantics; dropped the `cap` parameter.

Other changes:

* Replace `Lru.M.cache` with more general `Lru.memo`.

* Queues with 0 initial capacity are legal.

* Add `trim` to shrink a queue to its capacity, as queues are no longer guaranteed to
  have size smaller than capacity.

* `find` gets the `promote` parameter, allowing queries that do not change the order.

* `add` gets the `trim` parameter, allowing insertions that do not drop old entries.

## v0.1.1 2016-11-28

* Fix missing dep on `psq` in META.

## v0.1.0 2016-11-22

First release.
