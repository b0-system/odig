# ocaml-ppx_gen_rec

A ppx rewriter that transforms a
[recursive module](https://caml.inria.fr/pub/docs/manual-ocaml/extn.html#sec235)
expression into a `struct`.

If you write a recursive module like this:

```
module rec Foo : sig
  type t = string
end = Foo
```

The compiler treats it like you wrote:

```
module rec Foo : sig
  type t = string
end = struct
  type t = string
end
```

If you try to use `ppx_deriving`, you get a `Undefined_recursive_module` exception, because `ppx_deriving` generates the signature but not the implementation:

```
module rec Foo : sig
  type t = string [@@deriving show]
end = Foo

(* is like writing *)
module rec Foo : sig
  type t = string
  val show: t -> string
end = struct
  type t = string
  let show _ = raise Undefined_recursive_module
end
```

Use `ppx_gen_rec` before `ppx_deriving` to generate an explicit struct, which will cause `ppx_deriving` to generate an implementation:

```
module%gen rec Foo : sig
  type t = string [@@deriving show]
end = Foo

(* becomes... *)
module rec Foo : sig
  type t = string [@@deriving show]
end = struct
  type t = string [@@deriving show]
end

(* which becomes... *)
module rec Foo : sig
  type t = string
  val show: t -> string
end = struct
  type t = string
  let show t = (* show stuff *)
end
```

## Usage

Just use `module%gen rec` instead of `module rec`:

```
module%gen rec Foo : sig
  type t = string [@@deriving show]
end = Foo
```


## License

ocaml-ppx_gen_rec is MIT licensed, as found in the LICENSE file.
