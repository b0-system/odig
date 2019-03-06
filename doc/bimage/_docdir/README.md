bimage — Image processing library
-------------------------------------------------------------------------------
%%VERSION%%

bimage is an image processing library for OCaml.

## Features

- Simple image type based on bigarrays
- Supports u8, u16, i32, i64, f32, f64, complex32 and complex64 datatypes
- Multiple layout support (Planar/Interleaved)
- Composable image operations
- Image I/O using ImageMagick/GraphicsMagick and FFmpeg in (`bimage-unix`)
- Support for displaying images using GTK (`bimage-gtk`) or SDL (`bimage-sdl`)

bimage is distributed under the ISC license.

Homepage: https://github.com/zshipko/bimage

## Installation

bimage can be installed with `opam`:

    opam install bimage

Additionally, `bimage-unix`, which provides `ImageMagick` and `FFmpeg` bindings, can be installed by running:

    opam install bimage-unix

If you don't use `opam` consult the [`opam`](opam) file for build
instructions.

## Examples

An example showing how to create an image and how to use `Image.for_each`:

```ocaml
open Bimage

let _ =
(* Create a new image *)
let a = Image.create u8 gray 64 64 in

(* Iterate over each pixel *)
let _ =
    Image.for_each (fun x y _px ->
        set a x y (x + y)
    ) a
in

(* Save the image using ImageMagick *)
Bimage_unix.Magick.write "test1.jpg" a
```

An example using `Op.t` to run a filter on an image:

```ocaml
open Bimage
open Bimage_unix

let _ =
(* Load an image using ImageMagick *)
let Some a = Magick.read "test/test.jpg" f32 rgb in

(* Create an operation to convert to grayscale and subtract 1.0 *)
let f = Op.(grayscale &- scalar 1.0) in

(* Create a destination image *)
let dest = Image.like f32 gray a in

(* Run the operation *)
let () = Op.eval f dest [| a |] in

(* Save the image using ImageMagick *)
Magick.write "test2.jpg" a
```

## Documentation

The documentation and API reference is generated from the source
interfaces. It can be consulted [online][doc] or via `odig doc
bimage`.

[doc]: https://zshipko.github.io/ocaml-bimage/

## Tests

In the distribution sample programs and tests are located in the
[`test`](test) directory. They can be built and run
with:

    dune runtest
