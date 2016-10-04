(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup
open Odig
open Odig.Private

(* Init configuration. *)

let conf = ref None

let init ?conf:c () =
  (* FIXME at the moment logs will be setup because of findlib we'll need
     to do that ourselves at some point though *)
  let c = match c with
  | Some c -> Ok c
  | None ->
      (Conf.(of_file default_file) >>| fun conf -> Ok conf)
      |> Logs.on_error ~pp:R.pp_msg ~use:(fun e -> Error e)
  in
  conf := Some c

let rec get_conf () = match !conf with
| None -> init (); get_conf ()
| Some c -> c

(* Loaders *)

let load_init_file cma =
  let init_base = Fpath.(basename @@ rem_ext cma) ^ "_top_init.ml" in
  let init = Fpath.(parent cma / init_base) in
  OS.File.exists init >>| function
  | false -> ()
  | true ->
      try
        Log.app (fun m -> m "Loading %a" Fpath.pp init);
        ignore (Toploop.use_file Format.err_formatter (Fpath.to_string init))
      with
      Symtable.Error e -> ()

let load_cma cma =
  Log.app (fun m -> m "Loading %a" Fpath.pp cma);
  begin
    try
      (* FIXME how to detect errors ? *)
      Topdirs.dir_directory (Fpath.(to_string @@ parent cma));
      Topdirs.dir_load Format.err_formatter (Fpath.to_string cma);
      load_init_file cma
    with
    | Symtable.Error e -> (* FIXME
                             why do y need compiler-lib.bytecomp for this symbol
                             why doesn't this get catched ? Is the
                             expunge business  ? *)
         R.error_msgf "%a" Symtable.report_error e
  end

let cma_for_cmi local global d =
  let find idx d =
    let add_cma acc (_, cmo) = match Cobj.Cmo.cma cmo with
    | None -> acc | Some cma -> cma :: acc
    in
    match List.fold_left add_cma [] (Cobj.Index.find_cmo idx d) with
    | [] -> None
    | [cma] -> Some cma
    | cma :: _ -> (* FIXME *)
       Log.warn (fun m -> m "multiple cmas for %s" (Cobj.Digest.to_hex d));
       Some cma
  in
  match find local d with
  | None -> find global d
  | Some _ as v -> v

let rec load_cma_rec local global loaded cma = (* Not T.R. *)
  let rec loop loaded = function
  | [] ->
      let cmis = Cobj.Cma.cmi_digests cma in
      if (Cobj.Digest.Set.subset cmis loaded) then Ok loaded else
      (load_cma (Cobj.Cma.path cma) >>| fun () ->
       Cobj.Digest.Set.union cmis loaded)
  | d :: ds ->
      if Cobj.Digest.Set.mem d loaded then loop loaded ds else
      match cma_for_cmi local global d with
      | None ->
          R.error_msgf "%s dep could not be found for %a"
            (Cobj.Digest.to_hex d)
            Fpath.pp (Cobj.Cma.path cma)
      | Some cma ->
          load_cma_rec local global (Ok loaded) cma >>= fun loaded ->
          loop loaded ds
  in
  loaded >>= fun loaded ->
  loop loaded (Cobj.Digest.Set.to_list (Cobj.Cma.cmi_deps cma))


let std_digests conf =       (* FIXME how to reliably find the stdlib *)
  match Pkg.find conf "ocaml" with
  | None -> R.error_msgf "Could not find the ocaml package in conf"
  | Some p ->
      let add_lib acc cma =
        acc
        >>= fun acc -> Cobj.Cma.read Fpath.(Pkg.libdir p / cma)
        >>| fun cma -> Cobj.Cma.cmi_digests ~init:acc cma
      in
      List.fold_left add_lib (Ok Cobj.Digest.Set.empty)
        [ "stdlib.cma";
          "unix.cma" (* already needed by odig and trips
                        the toplevel if loaded twice *);
          (* FIXME maybe we should also add odig's deps here.
             We need a boostrap story. *) ]

(* FIXME None deps, standalone cmo handling, cycle detection. *)

let load_libs conf objs =
  Pkg.conf_cobj_index conf >>= fun global ->
  let local = Cobj.Index.of_set () objs in
  let cmas = Cobj.cmas objs in
  List.fold_left (load_cma_rec local global) (std_digests conf) cmas

let get_dir = function (* FIXME realpath it. *)
| Some dir -> dir
| None ->
    let absent = Fpath.v "_build" in
    OS.Env.(value "ODIG_BUILD_DIR" path ~absent)

let load_libs ?dir () =
  let dir = get_dir dir in
  begin
    get_conf ()
    >>= fun conf -> load_libs conf (Cobj.set_of_dir dir)
    >>| fun _ -> ()
  end
  |> Log.on_error_msg ~use:(fun _ -> ())


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
