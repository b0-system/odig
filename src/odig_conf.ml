(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup

type t =
  { libdir : Fpath.t;
    docdir : Fpath.t;
    docdir_href : string option;
    cachedir : Fpath.t;
    trust_cache : bool; }

let trails_file cachedir = Fpath.(cachedir / "trails")

let default_file = Fpath.(Odig_etc.dir / "odig.conf")

let write_trails cachedir () =
  begin
    OS.Dir.exists cachedir >>= function
    | false -> Ok ()
    | true -> Odig_btrail.write (trails_file cachedir)
  end
  |> Logs.on_error_msg ~use:(fun _ -> ())

let v ?(trust_cache = false) ~cachedir ~libdir ~docdir ~docdir_href () =
  let trails_file = trails_file cachedir in
  (Odig_btrail.read ~create:true trails_file)
  |> Odig_log.on_error_msg ~level:Logs.Warning ~use:(fun _ -> ());
  at_exit (write_trails cachedir); (* FIXME more explicit *)
  { libdir; docdir; cachedir; docdir_href; trust_cache; }

let of_opam_switch ?trust_cache ?switch ?docdir_href () =
  let switch = match switch with
  | None -> Cmd.empty
  | Some s -> Cmd.(v "--switch" % s)
  in
  let get_dir opam d =
    OS.Cmd.(run_out Cmd.(opam % "config" %% switch % "var" % d) |> to_string)
    >>= fun p -> Fpath.of_string p
  in
  OS.Cmd.must_exist (Cmd.v "opam")
  >>= fun opam -> get_dir opam "lib"
  >>= fun libdir -> get_dir opam "doc"
  >>= fun docdir -> get_dir opam "prefix"
  >>= fun prefix -> Ok Fpath.(prefix / "var" / "cache" / "odig")
  >>= fun cachedir -> Ok (v ?trust_cache ~cachedir ~libdir ~docdir
                            ~docdir_href ())

let of_file ?trust_cache f =
  (* TODO better conf parsing *)
  let rec parse_directives opam libdir docdir docdir_href cachedir = function
  | (`Atom "opam", _) :: ds when not opam ->
      parse_directives true libdir docdir docdir_href cachedir ds
  | (`List [`Atom "libdir", _; `Atom dir, _ ], _) :: ds ->
      Fpath.of_string dir >>= fun dir ->
      parse_directives opam (Some dir) docdir docdir_href cachedir ds
  | (`List [`Atom "docdir", _; `Atom dir, _ ], _) :: ds ->
      Fpath.of_string dir >>= fun dir ->
      parse_directives opam libdir (Some dir) docdir_href cachedir ds
  | (`List [`Atom "docdir-href", _; `Atom href, _ ], _ ) :: ds ->
      parse_directives opam libdir docdir (Some href) cachedir  ds
  | (`List [`Atom "cachedir", _; `Atom dir, _ ], _ ) :: ds ->
      Fpath.of_string dir >>= fun dir ->
      parse_directives opam libdir docdir docdir_href (Some dir)  ds
  | (_, loc) :: ds ->
      R.error_msgf "%a: unknown configuration directive" Odig_sexp.pp_loc loc
  | [] ->
      Ok (opam, libdir, docdir, docdir_href, cachedir)
  in
  Odig_sexp.of_file f
  >>= fun ds -> parse_directives false None None None None ds
  >>= function
  | true, None, None, docdir_href, None -> of_opam_switch ?docdir_href ()
  | true, _, _, _, _ ->
      R.error_msgf "%a: inconsistent configuration" Fpath.pp f
  | _, None, _, _, _
  | _, _, None, _, _
  | _, _, _, _, None ->
      R.error_msgf "%a: incomplete configuration" Fpath.pp f
  | _, Some libdir, Some docdir, docdir_href, Some cachedir ->
      Ok (v ?trust_cache ~cachedir ~libdir ~docdir ~docdir_href ())

let libdir c = c.libdir
let docdir c = c.docdir
let docdir_href c = c.docdir_href
let cachedir c = c.cachedir
let trust_cache c = c.trust_cache

let pkg_cachedir c = Fpath.(c.cachedir / "cache")

let clear_cache c =
  let d = cachedir c in
  Odig_log.info (fun m -> m "Deleting %a" Fpath.pp d);
  OS.Dir.delete ~recurse:true d

let cached_pkgs_names c =
  OS.Dir.exists (cachedir c) >>= function
  | false -> Ok (String.Set.empty)
  | true ->
      OS.Dir.contents ~rel:true (pkg_cachedir c)
      >>| fun names -> String.Set.of_list @@ List.rev_map Fpath.to_string names

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
