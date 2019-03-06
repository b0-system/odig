cuid
====

CUID generator for OCaml.


<center>

[![Travis](https://img.shields.io/travis/marcoonroad/ocaml-cuid.svg?style=flat-square)](https://travis-ci.org/marcoonroad/ocaml-cuid)
<span> </span>
[![Coveralls github](https://img.shields.io/coveralls/github/marcoonroad/ocaml-cuid.svg?style=flat-square)](https://coveralls.io/github/marcoonroad/ocaml-cuid?branch=master)
<span> </span>
![GitHub tag](https://img.shields.io/github/tag/marcoonroad/ocaml-cuid.svg?style=flat-square)
<span> </span>
[![Github all releases](https://img.shields.io/github/downloads/marcoonroad/ocaml-cuid/total.svg?style=flat-square)](https://github.com/marcoonroad/ocaml-cuid/releases/)
<span> </span>
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](http://makeapullrequest.com)

</center>

<p/>

For further information, please refer to http://usecuid.org

### Installation

If available on OPAM, it's easily installed with:

```shell
$ opam install cuid
```

Otherwise, this library is also installable using
JBuilder within this root directory:

```shell
$ jbuilder install
```

### Usage

As library:

```ocaml
let cuid = Cuid.generate ( )
(* cuid is "c00p6veue0000072slgr067a3", for example *)
```

### Conclusion

PRs & issues are welcome. Have fun and imagine Sisyphus happy.
