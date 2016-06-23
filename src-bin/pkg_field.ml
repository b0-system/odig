(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup
open Opkg
open Opkg.Private

let lookup ~warn_error ~kind ~get ~undefined pkgs =
  let level = if warn_error then Logs.Error else Logs.Warning in
  let err = ref false in
  let add_pkg_value pkg acc = match get pkg with
  | Error (`Msg e) ->
      Logs.msg level (fun m -> m "%a" Fmt.text e);
      err := true;
      acc
  | Ok v when undefined v ->
      Logs.msg level (fun m -> m "package %s: No %s found" (Pkg.name pkg) kind);
      err := true;
      acc
  | Ok v -> (pkg, v) :: acc
  in
  let vs = List.rev (Pkg.Set.fold add_pkg_value pkgs []) in
  if !err && warn_error then Error () else Ok vs

let flatten ~rev values =
  let add_val pkg acc v = (pkg, v) :: acc in
  let add_vals acc (pkg, vs) = List.fold_left (add_val pkg) acc vs in
  let flat = List.fold_left add_vals [] values in
  if rev then flat else List.rev flat

(* Json values *)

let json_value ~show_pkg ~mem_n ~mem_v (p, v) =
  let pkg () = Json.str (Pkg.name p) in
  Json.(obj @@
        mem_if show_pkg "pkg" pkg ++
        mem mem_n (mem_v v))

let json_values ~show_pkg ~mem_n ~mem_v vs =
  let json_v = json_value ~show_pkg ~mem_n ~mem_v in
  let add_el a v = Json.(a ++ el (json_v v)) in
  Json.(arr @@ List.fold_left add_el empty vs)

(* Print values *)

let print_values ~show_pkg to_str vs =
  let print_v (p, v) =
    if show_pkg
    then Printf.printf "%s %s\n" (Pkg.name p) (to_str v)
    else Printf.printf "%s\n" (to_str v)
  in
  List.iter print_v vs

(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli

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
