(*---------------------------------------------------------------------------
   Copyright (c) 2016 The odig programmers. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup
open Odig
open Odig.Private

let show ~kind ~get conf pkgs warn_error show_pkg json =
  begin
    let undefined v = v = [] in
    Cli.lookup_pkgs conf pkgs >>= fun pkgs ->
    match Pkg_field.lookup ~warn_error ~kind ~get ~undefined pkgs with
    | Error () -> Ok 1
    | Ok values ->
        begin match json with
        | true ->
            let add_v a v = Json.(a ++ el (str v)) in
            let mem_v vs = Json.(arr @@ List.fold_left add_v empty vs) in
            Json.output stdout @@
            Pkg_field.json_values ~show_pkg ~mem_n:kind ~mem_v values
        | false ->
            let vs = Pkg_field.flatten ~rev:false values in
            Pkg_field.print_values ~show_pkg (fun x -> x) vs
        end;
        Ok 0
  end
  |> Cli.handle_error

(* Command line interface *)

open Cmdliner

let cmd_info ~cmd ~kind =
  let doc = strf "Show the %s of a package" kind in
  let sdocs = Manpage.s_common_options in
  let exits =
    Term.exit_info 0 ~doc:"packages exist and the lookups succeeded." ::
    Term.exit_info 1 ~doc:"with $(b,--warn-error), a lookup is undefined." ::
    Cli.indiscriminate_error_exit :: Term.default_error_exits
  in
  let man_xrefs = [ `Main ] in
  let man = [
    `S "DESCRIPTION";
    `P (strf "The $(tname) command shows the %s of a package." kind) ]
  in
  Cmdliner.Term.info cmd ~doc ~sdocs ~exits ~man_xrefs ~man

let cmd cmd ~kind ~get =
  let info = cmd_info ~cmd ~kind in
  let term =
    Term.(const (show ~kind ~get) $ Cli.setup () $ Cli.pkgs_or_all_opt $
          Cli.warn_error $ Cli.show_pkg $ Cli.json)
  in
  term, info

(* Commands *)

let authors_cmd =
  cmd "authors" ~kind:"authors" ~get:Pkg.authors

let deps_cmd =
  (* FIXME need more flags --optional --installed *)
  let deps p =
    Pkg.deps ~opts:true p >>| function s -> String.Set.elements s
  in
  cmd "deps" ~kind:"dependencies" ~get:deps

let maintainers_cmd =
  cmd "maintainers" ~kind:"maintainers" ~get:Pkg.maintainers

let tags_cmd =
  cmd "tags" ~kind:"tags" ~get:Pkg.tags

let version_cmd =
  (* FIXME avoid list, json output is absurd. *)
  let version p = Pkg.version p >>= function None -> Ok [] | Some v -> Ok [v] in
  cmd "version" ~kind:"version" ~get:version


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
