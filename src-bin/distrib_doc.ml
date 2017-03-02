(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup
open Odig

(* FIXME add json output *)

let rec print_file_contents show_pkg files =
  let rec loop = function
  | [] -> assert false
  | (p, f) :: fs ->
      begin
        OS.File.read f >>| fun contents ->
        let contents = String.trim contents in
        (if show_pkg
         then Printf.printf "%s\n%s\n" (Pkg.name p) contents
         else Printf.printf "%s\n" contents)
      end
      |> Logs.on_error_msg ~use:(fun _ -> ());
      if fs = [] then () else (Printf.printf "\x1C" (* fs *); loop fs)
  in
  loop files

let show_docs no_pager show_loc show_pkg = function
| [] -> Ok ()
| files ->
    Pager.find ~don't:no_pager >>= function
    | None -> Ok (print_file_contents show_pkg files)
    | Some pager ->
        let files = List.(rev (rev_map (fun (p, f) -> Cmd.p f) files)) in
        OS.Cmd.run Cmd.(pager %% of_list files)

let show ~kind get conf pkgs warn_error no_pager loc show_pkg =
  begin
    let undefined v = v = [] in
    Cli.lookup_pkgs conf pkgs >>= fun pkgs ->
    match Pkg_field.lookup ~warn_error ~kind ~get ~undefined pkgs with
    | Error () -> Ok 1
    | Ok values ->
        let files = Pkg_field.flatten ~rev:false values in
        begin match loc with
        | true ->
            Ok (Pkg_field.print_values ~show_pkg Fpath.to_string files)
        | false ->
            show_docs no_pager loc show_pkg files
        end
        >>= fun () -> Ok 0
  end
  |> Cli.handle_error

(* license specific show FIXME review that *)

let show_license_tags conf pkgs warn_error show_loc show_pkg =
  let loc pkg =
    let file = Pkg.opam_file pkg in
    OS.File.exists file >>= function
    | true -> Ok (print_endline (Fpath.to_string file))
    | false ->
        R.error_msgf "package %s: %a: No such file."
          (Pkg.name pkg) Fpath.pp file
  in
  let show_license pkg =
    Pkg.license_tags pkg >>= function
    | [] ->
        R.error_msgf "package %s: No license tags found" (Pkg.name pkg)
    | ls -> Ok (List.iter print_endline ls)
  in
  let show pkg =
    let level = if warn_error then Logs.Error else Logs.Warning in
    (if show_loc then loc pkg else show_license pkg)
    |> Logs.on_error_msg ~level ~use:(fun _ -> ())
  in
  begin
    Cli.lookup_pkgs conf pkgs >>= fun pkgs ->
    Pkg.Set.iter show pkgs; Ok 0
  end
  |> Cli.handle_error

let show_license conf pkgs warn_error no_pager loc show_pkg tag =
  if tag then show_license_tags conf pkgs warn_error loc show_pkg else
  show ~kind:"license" Pkg.licenses conf pkgs warn_error no_pager loc show_pkg

(* Command line interface *)

open Cmdliner

let cmd_info ~cmd ~kind =
  let doc = strf "Show the %s of a package" kind in
  let sdocs = Manpage.s_common_options in
  let envs =
    Term.env_info "PAGER" ~doc:"The pager used to display content" ::
    Term.env_info "TERM" ~doc:"See option $(b,--no-pager)." :: []
  in
  let exits =
    Term.exit_info 0 ~doc:"packages exist and the lookups succeeded." ::
    Term.exit_info 1 ~doc:"with $(b,--warn-error), a lookup is undefined." ::
    Cli.indiscriminate_error_exit ::
    Term.default_error_exits
  in
  let man_xrefs = [ `Main ] in
  let man =
    [ `S "DESCRIPTION";
      `P (strf "The $(tname) command shows the %s of a package. If
                invoked with $(b,--no-pager) and multiple files are output
                these are separated by a U+001C (file separator) control
                character." kind); ]
  in
  Cmdliner.Term.info cmd ~doc ~sdocs ~envs ~exits ~man_xrefs ~man

let cmd cmd ~kind ~get =
  Term.(const (show ~kind get) $ Cli.setup () $ Cli.pkgs_or_all_opt $
        Cli.warn_error $ Cli.no_pager $ Cli.loc $ Cli.show_pkg),
  cmd_info ~cmd ~kind

(* Commands *)

let readme_cmd =
  cmd "readme " ~kind:"readme" ~get:Pkg.readmes

let changes_cmd =
  cmd "changes" ~kind:"change log" ~get:Pkg.change_logs

let tag =
  let doc = "Read license tags from the package's opam file. Implies
             $(b,--no-pager)."
  in
  Arg.(value & flag & info ["t"; "tag"] ~doc)

let license_cmd =
  Term.(const show_license $ Cli.setup () $ Cli.pkgs_or_all_opt $
        Cli.warn_error $ Cli.no_pager $ Cli.loc $ Cli.show_pkg $ tag),
  cmd_info ~cmd:"license" ~kind:"license"

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
