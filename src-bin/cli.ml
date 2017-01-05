(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup
open Cmdliner

open Odig.Private

(* Manual *)

let common_opts = "COMMON OPTIONS"

let common_opts_man =
  [ `S common_opts; `P "These options are common to all commands." ]

let common_man =
  [ `S "ARGUMENTS";
    `S "OPTIONS";
  ] @ common_opts_man @ [
    `S "ENVIRONMENT VARIABLES"; ]

let see_also_main_man =
  [ `S "SEE ALSO";
    `P "odig(1)" ]

(* Converters *)

let path_arg =
  let parse s = match Fpath.of_string s with
  | Error (`Msg m) -> `Error m
  | Ok s -> `Ok s
  in
  parse, Fpath.pp

let cmd_arg =
  let parse s = match Cmd.of_string s with
  | Error (`Msg m) -> `Error m
  | Ok cmd -> `Ok cmd
  in
  parse, Cmd.pp

let pkg_name_arg =
  let parser v = match Odig.Pkg.name_of_string v with
  | Error (`Msg msg) -> `Error msg
  | Ok v -> `Ok v
  in
  parser, Fmt.string

(* Arguments *)

let loc =
  let doc = "Output content location (file path or URI) instead of \
             displaying content."
  in
  Arg.(value & flag & info ["l"; "loc"] ~doc)

let show_pkg =
  let doc = "Prefix output with the package name and a space or newline." in
  Arg.(value & flag & info ["p"; "show-pkg"] ~doc)

let json =
  let doc = "Output data in JSON." in
  Arg.(value & flag & info ["json"] ~doc)

let no_pager =
  let doc = "Do not display the content in a pager. This automatically
             happens if the TERM environment variable is 'dumb' or unset."
  in
  Arg.(value & flag & info ["no-pager"] ~doc)

let warn_error =
  let doc = "Turn warnings into errors." in
  Arg.(value & flag & info ["e"; "warn-error"] ~doc)

let odoc =
  let doc = "The odoc command to use." in
  let env = Arg.env_var "OPKG_ODOC" in
  let odoc = Cmd.v "odoc" in
  Arg.(value & opt cmd_arg odoc & info ["odoc"] ~env ~docv:"CMD" ~doc)

let ocamldoc =
  let doc = "The ocamldoc command to use." in
  let env = Arg.env_var "OPKG_OCAMLDOC" in
  let ocamldoc =
    let ocamldoc = Cmd.v "ocamldoc" in
    let ocamldoc_opt = Cmd.v "ocamldoc.opt" in
    (OS.Cmd.exists ocamldoc_opt >>| function
     | true -> ocamldoc_opt
     | false -> ocamldoc)
    |> R.ignore_error ~use:(fun _ -> ocamldoc)
  in
  Arg.(value & opt cmd_arg ocamldoc & info ["ocamldoc"] ~env ~docv:"CMD" ~doc)

let doc_force =
  let doc = "Force generation even if files are up-to-date." in
  Arg.(value & flag & info ["f"; "force"] ~doc)

let pkgs ?right_of () =
  let doc = "Package to consider (repeatable)." in
  let docv = "PKG" in
  let spec = match right_of with
  | None -> Arg.(pos_all pkg_name_arg [])
  | Some r -> Arg.(pos_right r pkg_name_arg [])
  in
  Arg.(value & spec & info [] ~doc ~docv)

let pkgs_or_all =
  let doc = "Packages to consider (repeatable). If no package is mentioned
             all of them is implied."
  in
  let docv = "PKG" in
  let pkgs = Arg.(pos_all pkg_name_arg []) in
  let wrap = function [] -> `All | pkgs -> `Pkgs pkgs in
  Term.(const wrap $ Arg.(value & pkgs & info [] ~doc ~docv))

let pkgs_or_all_opt =
  let all =
    let doc = "Show information for all packages." in
    Arg.(value & flag & info ["a"; "all"] ~doc)
  in
  let select all pkgs =
    if all then `Ok `All else
    match pkgs with
    | [] -> `Error (true, "No package specified")
    | pkgs -> `Ok (`Pkgs pkgs)
  in
  Term.(ret (const select $ all $ pkgs ()))

let docdir_href =
  let doc = "Overrides the configuration key docdir-href. For HTML
             generation, the base $(i,URI) under which $(i,DOCDIR) is
             accessible, expressed (if) relative to the root package
             list. If set to the empty string, links to $(i,DOCDIR) are
             made by relativizing $(i,DOCDIR) w.r.t. to the location
             of the generated HTML file."
  in
  let docv = "URI" in
  let parse = function "" -> `Ok None | s -> `Ok (Some s) in
  let print ppf v = match v with None -> () | Some v -> Fmt.string ppf v in
  let uri = parse, print in
  Arg.(value & opt (some uri) None & info [ "docdir-href" ] ~doc ~docv)

(* Basic setup for every command *)

let setup conf style_renderer log_level =
  Fmt_tty.setup_std_outputs ?style_renderer ();
  Logs.set_level log_level;
  Logs.set_reporter (Logs_fmt.reporter ~app:Fmt.stdout ());
  conf

let setup () =
  let style_renderer =
    let env = Arg.env_var "OPKG_COLOR" in
    Fmt_cli.style_renderer ~docs:common_opts ~env ()
  in
  let log_level =
    let env = Arg.env_var "OPKG_VERBOSITY" in
    Logs_cli.level ~docs:common_opts ~env ()
  in
  Term.(const setup $ Odig_cli.conf ~docs:common_opts () $
        style_renderer $ log_level)

let lookup_pkgs conf pkgs =
  let add acc pkg =
    acc
    >>= fun acc -> Odig.Pkg.lookup conf pkg
    >>= fun pkg -> Ok (Odig.Pkg.Set.add pkg acc)
  in
  match pkgs with
  | `Pkgs pkgs -> List.fold_left add (Ok Odig.Pkg.Set.empty) pkgs
  | `All -> Odig.Pkg.set conf

(* Error handling *)

let handle_error e = Log.on_error_msg ~use:(fun _ -> 3) e

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
