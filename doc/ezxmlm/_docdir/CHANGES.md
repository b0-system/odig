## v1.1.0 (2019-02-02)
* Add optional XML declaration for `to_string` and `to_channel`
  (#8 by @gaborigloi and review by @mseri)
* Automatically install toplevel printer on modern utop (@avsm)
* Port to dune from jbuilder (@avsm and @Leonidas-from-XIV in #9)
* Port opam metadata to 2.0 format (@avsm)
* Move to the `mirage/` GitHub organisation (@avsm)

## v1.0.2 (04/01/2018):

* Build with jbuilder and release with topkg
  (this also fixes an OCaml 4.06 -safe-string incompatibility with
   the oasis-generated code)
* Fixes to the ocamldoc markup to be more compliant with odoc.

## v1.0.1 (03-06-2014):

* Add `has_member` function to test if a tag is present in sub-nodes.
* Add Travis CI scripts.
* Regenerate OASIS build files with 0.4.4 (better dynlink support)

## v1.0.0 (02-11-2014):

* First public release.
