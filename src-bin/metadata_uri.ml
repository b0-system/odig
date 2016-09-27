(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup
open Odig
open Odig.Private

let show_uris uris browser background =
  let show (p, uri) = Webbrowser.reload ?prefix:None ~background ?browser uri in
  Log.on_iter_error_msg List.iter show uris

(* Command *)

let show
    ~kind ~get conf pkgs warn_error loc show_pkg json browser background
  =
  begin
    let kind_u = strf "%s URI" kind in
    let undefined v = v = [] in
    Cli.lookup_pkgs conf pkgs >>= fun pkgs ->
    match Pkg_field.lookup ~warn_error ~kind:kind_u ~get ~undefined pkgs with
    | Error () -> Ok 1
    | Ok uris ->
        let uris = Pkg_field.flatten ~rev:false uris in
        begin match json with
        | true ->
            Json.output stdout @@
            Pkg_field.json_values ~show_pkg ~mem_n:kind ~mem_v:Json.str uris
        | false ->
            match loc with
            | true -> Pkg_field.print_values ~show_pkg (fun x -> x) uris
            | false -> show_uris uris browser background
        end;
        Ok 0
  end
  |> Cli.handle_error

(* Command line interface *)

open Cmdliner

let cmd_info ~cmd ~kind =
  let doc = strf "Show the %s of a package" kind in
  let man =
    [ `S "DESCRIPTION";
      `P (strf "The $(b,$(tname)) command shows the %s of a package by
                opening or reloading the %s URI in a WWW browser."
            kind kind);
    ] @ Cli.common_man @ [
      `S "EXIT STATUS";
      `P "The $(b,$(tname)) command exits with one of the following values:";
      `I ("0", "packages exist and the lookups succeeded.");
      `I ("1", "with $(b,--warn-error), a lookup is undefined.");
      `I (">1", "an error occured.");
    ] @ Cli.see_also_main_man
  in
  Cmdliner.Term.info cmd ~sdocs:Cli.common_opts ~doc ~man

let cmd ?mkind cmd ~kind ~get =
  let mkind = match mkind with None -> kind | Some k -> k in
  let info = cmd_info ~cmd ~kind in
  let term =
    Term.(const (show ~kind:mkind ~get) $ Cli.setup () $ Cli.pkgs_or_all_opt $
          Cli.warn_error $ Cli.loc $ Cli.show_pkg $ Cli.json $
          Webbrowser_cli.browser $
          Webbrowser_cli.background)
  in
  term, info

(* Commands *)

(* FIXME json output multi pages in array ? *)

let homepage_cmd =
  cmd "homepage" ~kind:"homepage" ~get:Pkg.homepage

let issues_cmd =
  cmd "issues" ~kind:"issues" ~get:Pkg.issues

let online_doc_cmd =
  cmd "online-doc" ~mkind:"doc" ~kind:"online documentation" ~get:Pkg.online_doc

let repo_cmd =
  cmd "repo" ~mkind:"repo" ~kind:"source repository" ~get:Pkg.repo

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
