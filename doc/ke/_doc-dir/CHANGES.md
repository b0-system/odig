### v0.4 2019-07-24 Мостар (Боснa и Херцеговина)

* Call `dune subst` only when we _pin_ `ke`
* Update documentation (@dinosaure, @Drup)
  - Typography
  - Documentation about `Fke.tail{,_exn}`
  - Documentation about `Fke.rev_iter`
* Add `Fke.tail{,_exn}` (@dinosaure, #8)
* Add `Fke.rev_iter` (@dinosaure, #9)
* Compatible with `mirage`, dependance with `bigarray-compat` (@dinosaure, @TheLortex, #8)
* Update OPAM file (@dinosaure)

### v0.3 2019-04-10 Paris (France)

* Add `Rke.{,Weighted}.compress` function (fuzzed)
* Update `bechamel` benchmark
* Add `Rke{,.Weighted}.N.peek` function
* Fix bug on `Rke.Weighted.N.keep` function
* Add some tests

### v0.2 2019-01-14 Paris (France)

* Add pretty-printer
* Randomize `pop` action on the fuzzer
* Add tests on `Rke` and `Rke.Weighted` (with `alcotest`)
* Fix bug retrieved by `ocaml-git` (see 453633b)
* Add `rev_iter` function
* Fix bug on `Rke.N.keep_exn` (see 3951501)
* Add Travis CI support

### v0.1 2018-12-20 Paris (France)

* First release
