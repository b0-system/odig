(*---------------------------------------------------------------------------
   Copyright (c) 2016 The odig programmers. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup

type pos = int
type range = pos * pos
type src = File of Fpath.t
type loc = src * range

let no_loc = File (Fpath.v "?"), (-1, -1)

let pos src pos = src, (pos, pos + 1)
let loc src start stop = src, (start, stop)

let pp_loc ppf (src, (s, e)) = match src with
| File f -> Fmt.pf ppf "%a:%d-%d" Fpath.pp f s e

type error =
[ `Unclosed_quote
| `Unclosed_list
| `Illegal_escape_char of char ] * loc

let pp_error ppf (e, loc) = match e with
| `Unclosed_quote -> Fmt.pf ppf "%a: unclosed quote" pp_loc loc
| `Unclosed_list -> Fmt.pf ppf "%a: unclosed list" pp_loc loc
| `Illegal_escape_char c ->
    Fmt.pf ppf "%a: illegal escape character (%c)" pp_loc loc c

exception Error of error
let error e loc = raise (Error (e, loc))

type t = [ `Atom of string | `List of t list ] * loc

let atom a loc = (`Atom a), loc
let list a loc = (`List a), loc

let skip_white s = String.Sub.drop ~sat:Char.Ascii.is_white s
let skip_comment s =
  let is_comment_char c = not (Char.equal c '\n' || Char.equal c '\r') in
  String.Sub.drop ~sat:is_comment_char s

let rec skip s =
  let s = skip_white s in
  match String.Sub.head s with
  | Some ';' -> skip (skip_comment s)
  | Some _ | None -> s

let is_atom_char = function
| '(' | ')' | ';' -> false
| c when Char.Ascii.is_white c -> false
| _ -> true

let p_atom src s = match String.Sub.span ~min:1 ~sat:is_atom_char s with
| (a, _) when String.Sub.is_empty a -> assert false
| (a, rem) ->
    let loc = loc src (String.Sub.start_pos a) (String.Sub.stop_pos a) in
    let a = String.Sub.to_string a in
    atom a loc, rem

let p_qatom src s =
  let is_data = function '\\' | '"' -> false | _ -> true in
  let start_pos = String.Sub.start_pos s in
  let rec loop acc s =
    let data, rem = String.Sub.span ~sat:is_data s in
    match String.Sub.head rem with
    | Some '"' ->
        let acc = List.rev (data :: acc) in
        let loc = loc src start_pos (String.Sub.start_pos rem + 1) in
        let a = String.Sub.(to_string @@ concat acc) in
        atom a loc, (String.Sub.tail rem)
    | Some '\\' ->
        let rem = String.Sub.tail rem in
        begin match String.Sub.head rem with
        | Some ('"' | '\\' | 'n' | 'r' | 't' as c) ->
            let esc = match c with
            | '"' -> "\"" | '\\' -> "\\" | 'n' ->  "\n"
            | 'r' -> "\r" | 't' -> "\t" | _ -> assert false
            in
            loop (String.sub esc :: data :: acc) (String.Sub.tail rem)
        | Some c ->
            error (`Illegal_escape_char c) (pos src (String.Sub.start_pos rem))
        | None ->
            error `Unclosed_quote (pos src start_pos)
        end
    | None ->
        error `Unclosed_quote (pos src start_pos)
    | Some _ -> assert false
  in
  loop [] (String.Sub.tail s)

let rec p_list src s = (* TODO not t.r. *)
  let start_pos = String.Sub.start_pos s in
  let rec loop acc s =
    let s = skip s in
    match String.Sub.head s with
    | Some '"' ->
        let a, rem = p_qatom src s in
        loop (a :: acc) rem
    | Some '(' ->
        let l, rem = p_list src s in
        loop (l :: acc) rem
    | Some ')' ->
        let loc = loc src start_pos (String.Sub.start_pos s + 1) in
        list (List.rev acc) loc, (String.Sub.tail s)
    | Some _ ->
        let a, rem = p_atom src s in
        loop (a :: acc) rem
    | None ->
        error `Unclosed_list (pos src (String.Sub.stop_pos s))
  in
  loop [] (String.Sub.tail s)

let of_string ~src s =
  let s = String.Sub.of_string s in
  let rec loop acc s =
    let s = skip s in
    match String.Sub.head s with
    | Some '(' ->
        let l, rem = p_list src s in
        loop (l :: acc) rem
    | Some '"' ->
        let a, rem = p_qatom src s in
        loop (a :: acc) rem
    | Some _ ->
        let a, rem = p_atom src s in
        loop (a :: acc) rem
    | None ->
        Ok (List.rev acc)
  in
  try loop [] s with
  | Error e -> R.error_msgf "%a" pp_error e

let of_file f =
  OS.File.read f
  >>= fun s -> of_string ~src:(File f) s

let to_file f l = failwith "TODO"

module Codec = struct

  type error = R.msg
  let pp_error = R.pp_msg
  exception Error of error

  let err ~kind s =
    raise (Error (R.msg "TODO"))

  type sexp = t
  type 'a t =
    { kind : string;
      enc : 'a -> sexp;
      dec : sexp -> 'a; }

  let v ~kind ~enc ~dec = { kind; enc; dec }

  let kind c = c.kind
  let enc c = c.enc
  let dec c = c.dec
  let with_kind kind c = { c with kind }

  let dec_result c s = try Ok (dec c s) with
  | Error e -> R.error e

  let write file c v = to_file file [(enc c v)]
  let read file c =
    of_file file >>= fun s ->
    try Ok (dec c (List.hd s) (* FIXME *)) with Error e -> R.error e

  (** {1:base Base type codecs} *)

  let atom a = atom a no_loc
  let list l = list [] no_loc

  let unit =
    let kind = "unit" in
    let enc = function () -> list [] in
    let dec = function `List [], _ -> () | s -> err ~kind s in
    v ~kind ~enc ~dec

  let const value =
    let kind = "const" in
    let enc = function _ -> atom "const" in
    let dec = function `Atom "const", _ -> value | s -> err ~kind s in
    v ~kind ~enc ~dec

  let bool =
    let kind = "bool" in
    let enc = function true -> atom "true" | false -> atom "false" in
    let dec = function
    | `Atom b, _ as s ->
        (try bool_of_string b with Invalid_argument  _ -> err ~kind s)
    | s -> err ~kind s
    in
    v ~kind ~enc ~dec

  let int =
    let kind = "int" in
    let enc = function v -> atom (strf "%d" v) in
    let dec = function
    | `Atom v, _ as s -> (try int_of_string v with Failure _ -> err ~kind s)
    | s -> err ~kind s
    in
    v ~kind ~enc ~dec

  let string =
    let kind = "string" in
    let enc = function s -> atom s in
    let dec = function `Atom s, _ -> s | s -> err ~kind s in
    v ~kind ~enc ~dec

  let option some =
    let kind = strf "%s option" (kind some) in
    let enc = function
    | None -> list [atom "none"]
    | Some v -> list [atom "some"; (enc some) v ]
    in
    let dec = function
    | `List [ `Atom ("none" | "None"), _ ], _ -> None
    | `List [ (`Atom ("some" | "Some"), _); v], _ -> Some ((dec some) v)
    | s -> err ~kind s
    in
    v ~kind ~enc ~dec

  let result ~ok ~error =
    let kind = strf "(%s, %s) result" (kind ok) (kind error) in
    let enc = function
    | Ok v -> list [atom "ok"; (enc ok) v ]
    | Error e -> list [atom "error"; (enc error) e ]
    in
    let dec = function
    | `List [ `Atom ("ok" | "Ok"), _; v], _ -> Ok ((dec ok) v)
    | `List [ `Atom ("error" | "Error"), _; e], _ -> Error ((dec error) e)
    | s -> err ~kind s
    in
    v ~kind ~enc ~dec

  let _list c =
    let kind = strf "%s list" (kind c) in
    let enc l = list List.(rev @@ rev_map (enc c) l) in
    let dec = function
    | `List l, _ -> List.(rev @@ rev_map (dec c) l)
    | s -> err ~kind s
    in
    v ~kind ~enc ~dec

  let pair c0 c1 =
    let kind = strf "(%s * %s)" (kind c0) (kind c1) in
    let enc (v0, v1) = list [(enc c0) v0; (enc c1) v1] in
    let dec = function
    | `List [ v0; v1 ], _ -> (dec c0) v0, (dec c1) v1
    | s -> err ~kind s
    in
    v ~kind ~enc ~dec

  let t2 = pair

  let t3 c0 c1 c2 =
    let kind = strf "(%s * %s * %s)" (kind c0) (kind c1) (kind c2) in
    let enc (v0, v1, v2) = list [(enc c0) v0; (enc c1) v1; (enc c2) v2 ] in
    let dec = function
    | `List [ v0; v1; v2 ], _ -> (dec c0) v0, (dec c1) v1, (dec c2) v2
    | s -> err ~kind s
    in
    v ~kind ~enc ~dec

  let t4 c0 c1 c2 c3 =
    let kind =
      strf "(%s * %s * %s * %s)" (kind c0) (kind c1) (kind c2) (kind c3)
    in
    let enc (v0, v1, v2, v3) =
      list [(enc c0) v0; (enc c1) v1; (enc c2) v2; (enc c3) v3 ]
    in
    let dec = function
    | `List [ v0; v1; v2; v3 ], _ ->
        (dec c0) v0, (dec c1) v1, (dec c2) v2, (dec c3) v3
    | s -> err ~kind s
    in
    v ~kind ~enc ~dec

  let t5 c0 c1 c2 c3 c4 =
    let kind =
      strf "(%s * %s * %s * %s * %s)"
        (kind c0) (kind c1) (kind c2) (kind c3) (kind c4)
    in
    let enc (v0, v1, v2, v3, v4) =
      list [(enc c0) v0; (enc c1) v1; (enc c2) v2; (enc c3) v3; (enc c4) v4 ]
    in
    let dec = function
    | `List [ v0; v1; v2; v3; v4 ], _ ->
        (dec c0) v0, (dec c1) v1, (dec c2) v2, (dec c3) v3, (dec c4) v4
    | s -> err ~kind s
    in
    v ~kind ~enc ~dec

  let view ?(kind = "unknown") (inj, proj) c =
    let enc v = enc c (inj v) in
    let dec s = proj (dec c s) in
    v ~kind ~enc ~dec

  let list = _list
end




(*---------------------------------------------------------------------------
   Copyright (c) 2016 The odig programmers

   Permission to use, copy, modify, and/or distribute this software for any
   purpose with or without fee is hereby granted, provided that the above
   copyright notice and this permission notice appear in all copies.

   THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
   WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
   MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
   ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
   WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
   ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
   OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
  ---------------------------------------------------------------------------*)
