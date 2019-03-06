1.6 2018-09-07
--------------

- Port to Dune (not the former Jbuilder) and dune-release.
- Fix some typos in the documentation.

1.5 2018-05-17
--------------

- Port to Dune/Jbuilder and Topkg.
- Add option `--all` to the `Tree.arg`.
- Fix uncaught exception in `Tree.run_global`.



Very old changes
----------------

2004-08-22  Troestler Christophe  <chris_77@users.sourceforge.net>

* benchmark.ml: Code mostly rewritten to improve clarity (and to
  correct some bugs).  Allows to return multiple times for a given
  test.  Student's statistical test to determine whether two rates
  are significantly different (see `log_gamma`, `betai`,
  `cpl_student_t`, `comp_rates` and `different_rates`).

* benchmark.mli: The documentation is greatly improved.  Functions
  `make`, `add`, `sub` instead of `create`, `sum`, `diff` for
  uniformity with the OCaml standard library.

2004-08-18  Troestler Christophe  <chris_77@users.sourceforge.net>

* benchmark: Checked Doug Bagley module in CVS.
