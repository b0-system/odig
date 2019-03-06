# varint

A simple varint implementation modeled after the one found in Go's standard library.


Originally I wrote it because I wanted to implement a protocol in ocaml that used it, but did not want to use piqi, or protobuf. 

What varint encoding does is that you can input an int32 or int64, and for smaller numbers, it will take up less space, protobuf uses this technique for field length prefixing,  as a result it is more space efficient than using an 32 bit or 64 bit int, but on the other hand it does take more CPU time.




Also please note it only works with unsigned values meaning you can't encode negatives.


Here are a few examples that show how to use it.  

```ocaml
open Varint

let i = 412l in
let buf = VarInt32.to_cstruct i in

Printf.printf "%d \n" (Cstruct.len buf);
VarInt32.of_cstruct buf |> Int32.to_int in


```





```ocaml
open Varint

let module LFP = LengthFieldPrefixing(VarInt32) in
let hello = "hello friend, this world is an ugly place." in


let msg = Cstruct.of_string hello in 
let buf = LFP.encode msg |> Mstruct.of_cstruct in

let got = LFP.decode buf |> Cstruct.to_string in
Printf.printf "encoded %s\ndecoded %s" hello got;  

```