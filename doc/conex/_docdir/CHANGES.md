## 0.10.1 (2018-09-08)

* re-add LICENSE.md file (with a 2 clause BSD license)

## 0.10.0 (2018-09-03)

* adjusted to new conex design, lots of breaking changes
* opam_encoding: maps use identifiers now, instead of strings - as does alg_type
* conex_resource: use alg=data for encoding digests (instead of [ alg ; data ])
* conex_resource: use hex encoding, rather than base64 for checksums
* rename "package" to "releases" ; rename "release" to "checksums" (filenames)
* conex_unix_private_key: store private keys in ~/.conex/<id>.private, instead
  of having the repository included in the filename.  this removes lots of magic
  from conex_author
* conex_private: new module gathering private key handling and operations,
  replacing conex_unix_private_key and conex_crypto.SIGN

## 0.9.2 (2017-02-18)

* conex_author: status subcommand: handle id argument properly

## 0.9.1 (2017-02-18)

* conex_author:
  - key subcommand: argument 'all' queued invalid resources (using id = all)
  - init subcommand: sign at the end, to have a public key in the index
  - status subcommand: fix argument processing if both id and repo are present
  - verify subcommand: require repo, do not use id
* crypto: trim result from `pub_of_priv` (nocrypto appends a newline, and breaks checksum)
* conex: verify_janitors could never succeed (unless quorum = 0), because the
   team janitors (repo.teams) was empty while validating the team resource

## 0.9.0 (2017-02-16)

* initial release