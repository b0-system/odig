(******************************************************************************)
(* Copyright (c) 2014-2016 Skylable Ltd. <info-copyright@skylable.com>        *)
(*                                                                            *)
(* Permission to use, copy, modify, and/or distribute this software for any   *)
(* purpose with or without fee is hereby granted, provided that the above     *)
(* copyright notice and this permission notice appear in all copies.          *)
(*                                                                            *)
(* THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES   *)
(* WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF           *)
(* MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR    *)
(* ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES     *)
(* WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN      *)
(* ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF    *)
(* OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.             *)
(******************************************************************************)

(* This code is in the public domain *)
#use "topfind"
#require "anycache,unix"

open Result
let cache = Anycache.create 1024

let lookup name =
  Printf.printf "Looking up %s\n" name;
  try Ok (Unix.getaddrinfo name "" [])
  with e -> Error e

let cached_lookup = Anycache.with_cache cache lookup

let print_result = function
  | Ok lst -> Printf.printf "Got %d addresses\n" (List.length lst);
  | Error e -> raise e

let () =
  print_result (cached_lookup "example.com");
  print_result (cached_lookup "example.com");
  print_result (cached_lookup "example.net");
