(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup
open Odig
open Odig.Private

let show ~background ~prefix ?browser uris =
  Log.on_iter_error_msg List.iter
    (Webbrowser.reload ~background ~prefix ?browser) uris

let file_uri p = strf "file://%a" Fpath.pp p

let add_file not_found file acc =
  begin
    OS.File.exists file >>| function
    | true -> file_uri file :: acc
    | false -> not_found (); acc
  end
  |> Logs.on_error_msg ~use:(fun _ -> acc)

let root_not_found tool () =
  Logs.warn (fun m -> m "@[No doc found,@ try 'odig %s'@]" tool)

let pkg_not_found tool pkg () =
  let n = Odig.Pkg.name pkg in
  Logs.warn (fun m -> m "%s: @[No doc found,@ try 'odig %s %s'@]" n tool n)

(* odoc *)

let add_odoc_root conf =
  add_file (root_not_found "odoc")
    Fpath.(Odig.Odoc.htmldir conf None / "index.html")

let add_odoc_pkg pkg =
  add_file (pkg_not_found "odoc" pkg)
    Fpath.(Odig.Odoc.htmldir (Odig.Pkg.conf pkg) (Some pkg) / "index.html")

(* ocamldoc *)

let add_ocamldoc_root conf =
  add_file (root_not_found "ocamldoc")
    Fpath.(Odig.Ocamldoc.htmldir conf None / "index.html")

let add_ocamldoc_pkg pkg =
  add_file (pkg_not_found "ocamldoc" pkg)
    Fpath.(Odig.Ocamldoc.htmldir (Odig.Pkg.conf pkg) (Some pkg) / "index.html")

(* Command *)

let api conf browser background prefix pkgs backend =
  begin
    let add odoc_v ocamldoc_v acc = match backend with
    | `Odoc -> odoc_v acc
    | `Ocamldoc -> ocamldoc_v acc
    | `Compare -> odoc_v @@ ocamldoc_v acc
    in
    let uris = match pkgs with
    | [] -> Ok (add (add_odoc_root conf) (add_ocamldoc_root conf) [])
    | pkgs ->
        let add_pkg pkg acc =
          add (add_odoc_pkg pkg) (add_ocamldoc_pkg pkg) acc
        in
        Cli.lookup_pkgs conf (`Pkgs pkgs) >>= fun pkgs ->
        Ok (List.rev (Pkg.Set.fold add_pkg pkgs []))
    in
    uris
    >>= fun uris -> Ok (show ~background ~prefix ?browser uris)
    >>= fun () -> Ok 0
  end
  |> Cli.handle_error

(* Command line interface *)

open Cmdliner

let backend =
  let odoc =
    let doc = "Show odoc output (default)." in
    `Odoc, Arg.info ["odoc"] ~doc
  in
  let ocamldoc =
    let doc = "Show ocamlbuild output." in
    `Ocamldoc, Arg.info ["ocamldoc"] ~doc
  in
  let compare =
    let doc = "Show both odoc and ocamlbuild output for comparison." in
    `Compare, Arg.info ["c"; "compare"] ~doc
  in
  Arg.(value & vflag `Odoc [odoc; ocamldoc; compare])

let cmd =
  let doc = "Show package API documentation" in
  let sdocs = Manpage.s_common_options in
  let exits = Cli.exits in
  let man_xrefs = [ `Main ] in
  let man =
    [ `S "DESCRIPTION";
      `P "The $(tname) command shows the API documentation of a package." ]
  in
  Term.(const api $ Cli.setup () $ Webbrowser_cli.browser $
        Webbrowser_cli.background $ Webbrowser_cli.prefix $ Cli.pkgs () $
        backend),
  Term.info "doc" ~doc ~sdocs ~exits ~man_xrefs ~man

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
