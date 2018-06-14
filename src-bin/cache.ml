(*---------------------------------------------------------------------------
   Copyright (c) 2016 The odig programmers. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup
open Odig
open Odig.Private

let iter_pkgs conf pkgs f =
  Cli.lookup_pkgs conf pkgs >>|
  fun pkgs -> Log.on_iter_error_msg Pkg.Set.iter f pkgs

let path conf pkgs =
  let pr_dir d = Fmt.pr "%a@." Fpath.pp d in
  match pkgs with
  | `All -> pr_dir (Conf.cachedir conf); Ok ()
  | `Pkgs _ as pkgs ->
      let pr_dir p = pr_dir (Pkg.cachedir p); Ok () in
      iter_pkgs conf pkgs pr_dir

let clear conf pkgs = match pkgs with
| `All -> Conf.clear_cache conf
| `Pkgs _ as pkgs -> iter_pkgs conf pkgs Pkg.clear_cache

let refresh conf pkgs = iter_pkgs conf pkgs Pkg.refresh_cache

let pp_status ppf status =
  let style, status, pad = match status with
  | `New -> `Blue, " NEW ", ""
  | `Stale -> `Red, "STALE", ""
  | `Fresh -> `Green, "FRESH", ""
  | `Gone -> `Yellow, "GONE", " "
  in
  Fmt.pf ppf "%s[%a]" pad Fmt.(styled style string) status

let status conf pkgs =
  let pkg_status = function
  | `Gone n -> Ok (Log.app (fun m -> m "%a %s" pp_status `Gone n))
  | `Pkg p ->
      let s = Pkg.cache_status p |> Log.on_error_msg ~use:(fun _ -> `New) in
      Ok (Log.app (fun m -> m "%a %s" pp_status s (Pkg.name p)))
  in
  let rec make_list pkgs cached =
    let add_pkg p acc = String.Map.add (Pkg.name p) (`Pkg p) acc in
    let add_gone n acc = match String.Map.mem n acc with
    | true -> acc
    | false -> String.Map.add n (`Gone n) acc
    in
    let m = Pkg.Set.fold add_pkg pkgs String.Map.empty in
    let m = String.Set.fold add_gone cached m in
    List.rev @@ String.Map.fold (fun _ v acc -> v :: acc) m []
  in
  let cached = match pkgs with
  | `All -> Conf.cached_pkgs_names conf
  | `Pkgs _ -> Ok String.Set.empty
  in
  cached
  >>= fun cached -> Cli.lookup_pkgs conf pkgs
  >>= fun pkgs ->
  let pkgs = make_list pkgs cached in
  Ok (Log.on_iter_error_msg List.iter pkg_status pkgs)

let trails conf pkgs =
  let root = Conf.pkg_cachedir conf in
  Ok (Log.app (fun m -> m "%a" (Trail.pp_dot_universe ~root) ());)

let do_action conf action pkgs = match action with
| `Path -> path conf pkgs
| `Clear -> clear conf pkgs
| `Refresh -> refresh conf pkgs
| `Status -> status conf pkgs
| `Trails -> trails conf pkgs

let cache conf action pkgs =
  begin
    let pkgs = match pkgs with [] -> `All | pkgs -> `Pkgs pkgs in
    do_action conf action pkgs >>= fun () -> Ok 0
  end
  |> Cli.handle_error

(* Command line interface *)

open Cmdliner

let action =
  let action = [
    "path", `Path; "clear", `Clear; "refresh", `Refresh; "status", `Status;
    "trails", `Trails; ]
  in
  let doc = strf "The action to perform. $(docv) must be one of %s."
      (Arg.doc_alts_enum action)
  in
  let action = Arg.enum action in
  Arg.(required & pos 0 (some action) None & info [] ~doc ~docv:"ACTION")

let cmd =
  let doc = "Operate on the odig cache" in
  let sdocs = Manpage.s_common_options in
  let exits = Cli.exits in
  let man_xrefs = [ `Main ] in
  let man = [
    `S "SYNOPSIS";
    `P "$(mname) $(tname) $(i,ACTION) [$(i,OPTION)]... [$(i,PKG)]...";
    `S "DESCRIPTION";
    `P "The $(tname) command operates on the odig cache. If no packages
        are specified, operates on all packages.";
    `S "ACTIONS";
    `I ("$(b,path)", "Display path(s) to the cache.");
    `I ("$(b,clear)", "Clears the cache.");
    `I ("$(b,refresh)", "Refreshes the cache.");
    `I ("$(b,status)", "Display cache status.");
    `I ("$(b,trails)", "Show trails."); ]
  in
  Term.(const cache $ Cli.setup () $ action $ Cli.pkgs ~right_of:0 ()),
  Term.info "cache" ~doc ~sdocs ~exits ~man ~man_xrefs

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
