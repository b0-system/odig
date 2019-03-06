# OBEAM

[![CircleCI](https://circleci.com/gh/yutopp/obeam.svg?style=svg)](https://circleci.com/gh/yutopp/obeam)

**WIP**
obeam (御-BEAM) is a utility library for parsing BEAM format(and Erlang External Term Format, etc) which is written in OCaml.

Supported compilers which generate BEAM files are

- Erlang/OTP 19
- Erlang/OTP 20
- Erlang/OTP 21

## Installation
### Using opam pin

```
opam pin add obeam .
```

## Run examples

```
make test
erlc test/test01.erl
_build/default/example/read_beam.exe test01.beam
```

### Authors

- [@yutopp](https://github.com/yutopp)
- [@amutake](https://github.com/amutake)

obeam has been greatly improved by [many contributors](https://github.com/yutopp/obeam/graphs/contributors)!
