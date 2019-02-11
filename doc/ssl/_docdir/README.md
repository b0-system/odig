OCaml-SSL - OCaml bindings for the libssl
=========================================

* Author: Samuel Mimram <samuel.mimram@ens-lyon.org>
* Email: savonet-users@lists.sourceforge.net
* Homepage: http://savonet.sourceforge.net/

Copyright (c) 2003-2015 the Savonet Team.

Installation
------------

`ocaml-ssl` can be installed via [OPAM](https://opam.ocaml.org):

```
opam install ssl
```

Is this library thread-safe?
----------------------------

Yes it is if and only if the first function you call in ocaml-ssl is
`Ssl_threads.init` (and the second one should be `Ssl.init`).


Creating a self-signed ssl certificate
--------------------------------------

To get started quickly you can create a self-signed ssl certificate using
openssl.

1. First, create a 1024-bit private key to use when creating your CA.:
   `openssl genrsa -des3 -out privkey.pem 1024`
2. Create a master certificate based on this key, to use when signing other
   certificates:
   `openssl req -new -x509 -days 1001 -key privkey.pem -out cert.pem`

SSL acknowledgment
------------------

This product includes software developed by the OpenSSL Project for use in the
[OpenSSL Toolkit](http://www.openssl.org/).

License
-------

This library is released under the LGPL version 2.1 with
the additional exemption that compiling, linking, and/or using OpenSSL is
allowed.

As a special exception to the GNU Library General Public License, you
may also link, statically or dynamically, a "work that uses the Library"
with a publicly distributed version of the Library to produce an
executable file containing portions of the Library, and distribute
that executable file under terms of your choice, without any of the
additional requirements listed in clause 6 of the GNU Library General
Public License.  By "a publicly distributed version of the Library",
we mean either the unmodified Library, or a
modified version of the Library that is distributed under the
conditions defined in clause 3 of the GNU Library General Public
License.  This exception does not however invalidate any other reasons
why the executable file might be covered by the GNU Library General
Public License.

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

The examples are under the GPL licence version 2.0.
