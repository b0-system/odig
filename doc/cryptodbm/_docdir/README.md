# ocaml-cryptodbm

cryptodbm is an **[OCaml](http://ocaml.org/) library** that provides an encrypted layer over the [dbm library](https://github.com/ocaml/dbm): access to serverless, key-value databases with symmetric encryption.

## Install

Install with [opam](https://opam.ocaml.org/): `opam install cryptodbm`

## API Documentation

The [Cryptodbm API](https://lebotlan.github.io/ocaml-cryptodbm/index.html).
See also the examples/ dir.

The ocamlfind package name is `cryptodbm`.


## Overview

This library provides an encrypted layer on top of the [Dbm](https://github.com/ocaml/dbm) and [Cryptokit](https://github.com/xavierleroy/cryptokit/) packages. The improvements over Dbm are:
* A single database file may contain **several independent subtables**, identified by a name (a string).
* Each subtable can be **signed and encrypted individually**, or encrypted using a global password.
* The whole file can be signed.
* **Obfuscating data** is -optionally- appended to keys, data, and to the whole table, so that two databases with
   the same content look significantly different, once encrypted.
* Encryption is symmetric: encryption and decryption both use the same password.
* Signature is symmetric: signing and verifying the signature both use the same signword.

As a quick example, the following uncrypted bindings (key => data):
```
        "john-doe"        => "age 36"
        "some secret"     => "The cake is a lie."
        "Motto"           => "For relaxing times, make it Suntory time"
```
are stored as follows in the encrypted file (with variations depending on the password, the salt, and other parameters):
```
 [S~j....O.Q..tk^.2] => [...F...).Hsl..tB]
 [...y;....~.:.6V.2] => [....I...JR..w.E9..G..q=...K....b]
 [..'.C...F.x.3K.y2] => [1.)9q..M...et.b.]
 [S.....5 Y....8..2] => [.D........2..u...q.......}Z.b..z.zo.}.l3l.....>.]
 [...xD;@.8..wV..P1....e}....u..`.2] => [hb..2.._B....Y?0....|.....tM....]
 [K.#i.7j..H.ZZ.^.2] => [..z....,........] v}
```

Including several subtables in the same
database file avoids having to deal with multiple files to store related information, 
and also prevents information leak through the number and sizes of a set of database files.

This library was primarily designed to store encrypted exam files on a university server. A common layout consists in
several subtables encrypted with a global password, as well as an uncrypted subtable containing (public) meta-information.


## Typical example

```
   let table = open_append ~file:"/path/to/myfile" ~passwd:"my-secret-passwd" in

   let subtable = append_subtable table ~name:"here the subtable name" () in

   add subtable ~key:"key1" ~data:"data1" () ;
   add subtable ~key:"key2" ~data:"data2" () ;

   close table ;
   ()
```

## Contact

Didier Le Botlan, **github.lebotlan@dfgh.met**  where you replace **.met** by **.net**.
