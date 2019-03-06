## 0.1.2 (2019-02-16)

* `is_service` accepts numeric service names, used for ports in TLSA records (#1 by @cfcs)
* port to dune

## 0.1.1 (2018-07-07)

* `to_string` and `to_strings` now have an optional labeled `trailing` argument
  of type bool
* support for FQDN with trailing dot: `of_string "example.com."` now returns
  `Ok`, and is equal to `of_string "example.com"`
* fix and add tests for `drop_labels` and `drop_labels_exn`, where the semantics
  of the labeled `back` argument was inversed.

## 0.1.0 (2018-06-26)

* Initial release
