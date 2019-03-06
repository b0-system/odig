# ocaml-dtoa

This library provides a function that converts OCaml floats into strings, using the efficient Grisu3 algorithm.

The Grisu3 algorithm is described in ["Printing Floating-Point Numbers Quickly And Accurately with Integers"](http://www.cs.tufts.edu/~nr/cs257/archive/florian-loitsch/printf.pdf) by Florian Loitsch.

The implementation is adapted from [double-conversion](https://github.com/google/double-conversion).

## Current Status

Currently, this library exposes three functions:

- `ecma_string_of_float : float -> string`: formats the float according to the ECMAScript specification's implementation of [Number.prototype.toString](https://tc39.github.io/ecma262/#sec-tostring-applied-to-the-number-type). Notably, the output of this function is valid JSON.

- `shortest_string_of_float : float -> string`: formats the float as compactly as possible, for example returning `123e6` instead of `123000000` or `1.23e+08`.

- `g_fmt : float -> string`: formats the float in the same way as David M. Gay's [`g_fmt`](http://www.netlib.org/fp/g_fmt.c).

The underlying [`fast_dtoa()`](src/fast_dtoa.h) function computes the significand and exponent, which are formatted by the above functions in [`dtoa_stubs.c`](src/dtoa_stubs.c). It is a port of the [`double-conversion`](https://github.com/google/double-conversion) library from C++ to C.

Many features of `double-conversion` are still missing. Patches are welcome!

## License

`ocaml-dtoa` is [MIT-licensed](LICENSE).

## Author

`ocaml-dtoa` was created by Facebook for the [Flow](https://flow.org) project.
