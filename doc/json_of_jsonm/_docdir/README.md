# json_of_jsonm_lib

json_of_jsonm_lib is a JSON encoder and decoder library that converts text to and from a
`json` type. The library has the following features:

* Uses jsonm to do the actual stream encoding and decoding
* The `json` type is compatible with and a subset of yojson's `json` type
* Provides both string and channel interfaces by default
* The Json_string module provides a standard type `t` interface in addition to the
  `json` type
* Both `result` and exception functions are provided in most cases
* The Json_encoder_decoder functor allows additional IO mechanisms, including Async,
  to be defined easily. Note the Async version is not included to prevent
  dependencies on the Async libraries. See the examples for a basic implementation

## json type
The `json` type is defined as follows:
```ocaml
type json =
  [ `Null
  | `Bool of bool
  | `Float of float
  | `String of string
  | `List of json list
  | `Assoc of (string * json) list
  ]
```
Note that unlike yosjon there is no integer type as jsonm is a strict implementation
of JSON and JSON itself does not support integers. However, jsonm is round trip safe
for values that are integers on input and are within the JSON integer range (-2^53+1..2^53-1).
See [RFC 7159](https://tools.ietf.org/html/rfc7159) for more details

## API
The API provides two mechanisms for reporting errors: The standard functions return a
result type while the \_exn versions raise an exception.  Note that the `json` encoding
functions can also return an error as bad floating point values are detected.

### Module Json_string
The Json_string module provices the following types and functions

* type `json`
* type `t` is an alias for the `json` type
* `json_of_string_exn str` and `of_string str` convert `str` to type `json` raising an exception on error
* `json_of_string str` is the same as json_of_string_exn but returns a `(json, string) result`
   rather than raising an exception
* `json_to_string_exn json` and `to_string json` convert `json` to a string raising an exception on error
* `json_to_string str` is the same as json_to_string_exn but returns a `(unit, string) result`
   rather than raising an exception

### Module Json_channel
The Json_string module provices the following types and functions

* type `json`
* `json_of_channel in_channel` converts the text from `in_channel` into type `json`
  returning a `(json, string) result`
* `json_of_channel str_exn` is the same as json_of_channel but raises an exception rather
  than returning a result type
* `json_to_channel out_channel json` encodes `json` and writes the result to `out_channel`
  returning a `(unit, string) result`
* `json_to_channel_exn str` is the same as json_to_channel_exn but raises an exception rather
  than returning a result type


## Example usage
### Basic string
```ocaml
open Json_of_jsonm_lib

let () =
  let json = Json_string.of_string "{ \"a\": 1 }" in
  let json_s = Json_string.to_string json in
  Printf.printf "%s\n" json_s
```

Note that unlike the jsonm encoder the json_of_jsonm_lib encoder detects bad
floats (NaN and Inf) and returns an error, in this case the to_string function
generates an exception

### Channel input and output
```ocaml
open Json_of_jsonm_lib

let () =
  let inp = open_in "./x" in
  let outp = open_out "./z" in
  Json_channel.json_of_channel_exn inp
  |> Json_channel.json_to_channel_exn outp
```

### Using the Jsom_encoder_decoder functor
The following is an example of implementing the Async version using the
`Jsom_encoder_decoder` functor
```ocaml
open Async
open Json_of_jsonm_lib

module Json_async = struct
  module Json_of_async = Json_of_jsonm_monad.Make(struct
      type 'a t = 'a Deferred.t

      let return = Deferred.return
      let (>>=) = Deferred.Monad_infix.(>>=)
    end)


  let reader rd buf size =
    Reader.read rd ~len:size buf
    >>= function
    | `Eof -> return 0
    | `Ok len -> return len

  let read rd =
    let reader = reader rd in
    Json_of_async.decode ~reader

  let read_exn rd =
    let reader = reader rd in
    Json_of_async.decode_exn ~reader

  let write wr =
    let writer buf size = Writer.write ~len:size wr buf |> return in
    Json_of_async.encode ~writer

  let write_exn wr =
    let writer buf size = Writer.write ~len:size wr buf |> return in
    Json_of_async.encode_exn ~writer
end
```
The following shows a sample usage of the module
```ocaml
Reader.open_file "./x"
>>= fun rd -> Json_async.read_exn rd
>>= fun json -> Writer.open_file "./z"
>>= fun wr -> Json_async.write wr json
```
