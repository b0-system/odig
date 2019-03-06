# Ppx Protocol Conv
Ppx protocol conv (de)serialisers using deriving, which allows for
plugable (de)serialisers. [Api](https://andersfugmann.github.io/ppx_protocol_conv).

[![Build Status](https://travis-ci.org/andersfugmann/ppx_protocol_conv.svg?branch=master)](https://travis-ci.org/andersfugmann/ppx_protocol_conv)

## Features
The ppx supports the following features:
 * records
 * recursive and non-recursive types
 * variants
 * polymophic variants
 * All primitive types (except nativeint)

The following drivers exists
 * `Json` which serialises to `Yojson.Safe.t`
 * `Jsonm` which serialises to `Ezjsonm.value`
 * `Xml_light` which serialises to `Xml.xml list`
 * `Msgpack` which serialises to `Msgpck.t`
 * `Yaml` which serialises to `Yaml.t`

## Example Usage
```ocaml
open Protocol_conv
open Protocol_conv_json
type a = {
  x: int;
  y: string [@key "Y"]
} [@@deriving protocol ~driver:(module Json) ~flags:(`Mangle Json.mangle)]

type b = A of int
       | B of int [@key "b"]
       | C
[@@deriving protocol ~driver:(module Json)]
```

will generate the functions:
```ocaml
val a_to_json: a -> Json.t
val a_of_json: Json.t -> a

val b_to_json: a -> Json.t
val b_of_json: Json.t -> a
```

```ocaml
a_to_json { x=42; y:"really" }
```
Evaluates to
```ocaml
[ "x", `Int 42; "Y", `String "really"] (* Yojson.Safe.json *)
```

`to_protocol` deriver will generate serilisation of the
type. `of_protocol` deriver generates de-serilisation of the type,
while `protocol` deriver will generate both serilisation and de-serilisation functions.

Flags can be specified using the driver argument ~flags. For the json
and msgpack drivers, the `mangle` function transforms record label names to be
lower camelcase: a_bc_de -> aBcDe and a_bc_de_ -> aBcDe. Beware that
this may cause name collisions, which can only be determined at
runtime.

## Attributes
Record label names can be changed using `[@key <string>]`

Variant constructors names can also be changed using the `[@key <string>]`
attribute.

## Signatures
The ppx also handles signature, but disallows
`[@key ...]` and `~flags:...` as these does not impact signatures.

## Drivers

### Notes on type mappings
All included driver allow for the identity mapping by using the
`<driver>.t` type, i.e.:
```ocaml
type example = {
  json: Json.t; (* This has type Yojson.Safe.t *)
}
```
#### Json
Maps to and from `Yojson.Safe.t`

##### Options
the Msgpack driver accepts the following options:

| Option      | Description | Example |
|-------------|-------------|---------|
| `Mangle of (string -> string) | Maps record field names | `[@@deriving protocol ~driver:(module Json) ~flags:(`Mangle Json.mangle]` |
| | | Mangles names: `a_bc_de -> aBcDe`, `ab_ -> ab`, `ab_cd__ -> abCd' |

##### Types

| Ocaml type      | Generates | Accepts   |
|-----------------|-----------|-----------|
| string          | \`String  | \`String  |
| bytes           | \`String  | \`String  |
| int             | \`Int     | \`Int     |
| int32           | \`Int     | \`Int     |
| int64           | \`Int     | \`Int     |
| float           | \`Float   | \`Float   |
| unit            | \`List [] | \`List [] |
| Json.t          | Yojson.Safe.t  | Yojson.Safe.t  |

#### Jsonm
Converts to and from `Ezjsonm.value`. Types and arguments are the same
as for the Json implementation.

#### Msgpack
Msgpack driver maps to and from `Msgpck.t`.
To allow more finegrained control over generated type, the
msgpack module defines extra types. See table in #types section.

##### Options
The Msgpack driver accepts the following options:

| Option      | Description | Example |
|-------------|-------------|---------|
| `Mangle of (string -> string) | Maps record field names | `[@@deriving protocol ~driver:(module Json) ~flags:(`Mangle Json.mangle]` |
| | | Mangles names: `a_bc_de -> aBcDe`, `ab_ -> ab`, `ab_cd__ -> abCd' |


##### Types

| Ocaml type      | Generates | Accepts                           |
|-----------------|-----------|-----------------------------------|
| string          | String    | String, Bytes                     |
| int             | Int       | Int, Int32, Int64, Uint32, Uint64 |
| int32           | Int32     | Int32                             |
| int64           | Int64     | Int64                             |
| float           | Float64   | Float64, Float32                  |
| unit            | List []   | List []                           |
| Msgpack.uint32  | Uint32    | Uint32                            |
| Msgpack.uint64  | Uint64    | Uint64                            |
| Msgpack.bytes   | Bytes     | Bytes, String                     |
| Msgpack.float32 | Float32   | Float32                           |
| Msgpack.t       | MsgPck.t  | MsgPck.t                          |

#### Yaml
Converts to and from `Yaml.value`

##### Types

| Ocaml type      | Generates | Accepts   |
|-----------------|-----------|-----------|
| string          | \`String  | \`String  |
| bytes           | \`String  | \`String  |
| int             | \`Float   | \`Float*  |
| int32           | \`Float   | \`Float*  |
| int64           | \`Float   | \`Float*  |
| float           | \`Float   | \`Float   |
| unit            | \`List [] | \`List [] |
| Yaml.t          | Yaml.t    | Yaml.t    |

(*) Expects `abs(round(f) - f) < 0.000001`

## Custom drivers
It is easy to provide custom drivers by implementing the signature:

```ocaml
include Protocol_conv.Runtime.Driver with
  type t = ... and
  type 'a flags = ...
```

See the drivers directory for examples on how to implemented new drivers.
Submissions of new drivers are welcome.

## Not supported
* Generalised algebraic datatypes
* Extensible types
* Extensible polymorphic variants
* nativeint
