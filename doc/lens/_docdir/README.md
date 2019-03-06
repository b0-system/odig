Functional Lenses
=================

This package provides some basic types and functions for using lenses in OCaml.
Functional lenses are based on F# implementation in [FSharpX](https://github.com/fsharp/fsharpx). See [src/FSharpx.Extras/Lens.fs](https://github.com/fsharp/fsharpx/blob/master/src/FSharpx.Extras/Lens.fs) for the original implementation.  Written by Alessandro Strada.

See also:
* <http://bugsquash.blogspot.com/2011/11/lenses-in-f.html> Lenses in F#
* <http://stackoverflow.com/questions/8179485/updating-nested-immutable-data-structures> Stackoverflow question about Updating nested immutable data structures
* <http://stackoverflow.com/questions/5767129/lenses-fclabels-data-accessor-which-library-for-structure-access-and-mutatio> Haskell libraries for structure access and mutation
* <http://www.youtube.com/watch?v=efv0SQNde5Q> Functional lenses for Scala by Edward Kmett on YouTube
* <http://patternsinfp.wordpress.com/2011/01/31/lenses-are-the-coalgebras-for-the-costate-comonad/> Lenses are the coalgebras for the costate comonad by Jeremy Gibbons

Examples
========

First load `Lens` in utop.

    utop # #use "lens.ml";;

Given a couple of records

``` ocaml
    type car = {
        make : string;
        model: string;
        mileage: int;
      };;

    type editor = {
        name: string;
        salary: int;
        car: car;
    };;

    type book = {
        name: string;
        author: string;
        editor: editor;
    };;
```

Create a new nested record

``` ocaml
    let scifi_novel = {
       name =  "Metro 2033";
       author = "Dmitry Glukhovsky";
       editor =  {
         name = "Vitali Gubarev";
         salary =  1300;
         car =  {
           make = "Lada";
           model = "VAZ-2103";
           mileage = 310000
        }
      }
    };;
```

Now to construct a few lenses to access some things

``` ocaml
    let car_lens = {
        get = (fun x -> x.car);
        set = (fun v x -> { x with car = v })
      };;

    let editor_lens = {
        get = (fun x -> x.editor);
        set = (fun v x -> { x with editor = v })
    };;

    let mileage_lens = {
        get = (fun x -> x.mileage);
        set = (fun v x -> { x with mileage = v })

    };;
```

Using these lenses we can modify the mileage without having to unpack the record

``` ocaml
    let a = compose mileage_lens (compose car_lens editor_lens) in
    _set 10 scifi_novel a;;
```

Or using the `Infix` module we can do the same thing, only shorter.

``` ocaml
    _set 10 scifi_novel (editor_lens |-- car_lens |-- mileage_lens);;

    (* or *)

    ((editor_lens |-- car_lens |-- mileage_lens) ^= 10) @@ scifi_novel;;
```

Ppx syntax extension
--------------------

Lenses can be generated using the 'lens.ppx_deriving' plugin for [ppx_deriving](https://github.com/whitequark/ppx_deriving)

``` ocaml
#require "lens.ppx_deriving";;

type car = {
  make : string;
  model: string;
  mileage: int;
} [@@deriving lens];;

val car_make: (car, string) Lens.t
val car_model: (car, string) Lens.t
val car_mileage: (car, int) Lens.t
```

The `prefix` option can be used to prefix each lens name with `lens`.

``` ocaml
#require "lens.ppx_deriving";;

type car = {
  make : string;
  model: string;
  mileage: int;
} [@@deriving lens { prefix = true }];;

val lens_car_make: (car, string) Lens.t
val lens_car_model: (car, string) Lens.t
val lens_car_mileage: (car, int) Lens.t
```

The `submodule` option groups all the lenses in a sub-module `Lens`.

``` ocaml
#require "lens.ppx_deriving";;

type car = {
  make : string;
  model: string;
  mileage: int;
} [@@deriving lens { submodule = true }];;

module Lens :
  val make : (car, string) Lens.t
  val model : (car, string) Lens.t
  val mileage : (car, int) Lens.t
end
```

When the `prefix` and `submodule` options are combined, this is the module name which is prefixed.

``` ocaml
#require "lens.ppx_deriving";;

type car = {
  make : string;
  model: string;
  mileage: int;
} [@@deriving lens { submodule = true; prefix = true }];;

module CarLens :
  val make : (car, string) Lens.t
  val model : (car, string) Lens.t
  val mileage : (car, int) Lens.t
end
```
