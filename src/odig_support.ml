(*---------------------------------------------------------------------------
   Copyright (c) 2018 The odig programmers. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open B0_std
open B00

module Digest = struct
  include Digest
  let pp ppf d = Format.pp_print_string ppf (to_hex d)
  let pp_opt ppf = function
  | None -> Fmt.string ppf "--------------------------------"
  | Some d -> pp ppf d

  module Set = Set.Make (Digest)
  module Map = Map.Make (Digest)
end

module Pkg = struct
  type name = string
  type t = name * Fpath.t
  let name = fst
  let path = snd
  let pp ppf (n, p) = Fmt.pf ppf "%s %a" n (Fmt.tty [`Faint] Fpath.pp) p
  let pp_name ppf (n, p) = Fmt.string ppf n
  let pp_version ppf v =
    let v = if v = "" then "?" else v in
    Fmt.pf ppf "%a" (Fmt.tty_string [`Fg `Green]) v

  let equal = Pervasives.( = )
  let compare = Pervasives.compare
  let compare_by_caseless_name p p' =
    let n p = String.Ascii.lowercase (name p) in
    String.compare (n p) (n p')

  module T = struct type nonrec t = t let compare = compare end
  module Set = Set.Make (T)
  module Map = Map.Make (T)

  let of_dir dir =
    Log.time (fun _ m -> m "package list of %a" Fpath.pp dir) @@ fun () ->
    let ocaml_pkg () =
      let ocaml_where = Cmd.(arg "ocamlc" % "-where") in
      let p = Os.Cmd.run_out ocaml_where |> Result.to_failure in
      "ocaml", Fpath.of_string p |> Result.to_failure
    in
    try
      let add_pkg _ name dir acc =
        if name <> "ocaml" then (name, dir) :: acc else acc
      in
      let pkgs = Os.Dir.fold_dirs ~recurse:false add_pkg dir [] in
      let pkgs = pkgs |> Result.to_failure in
      List.sort compare_by_caseless_name (ocaml_pkg () :: pkgs)
    with Failure e -> Log.err (fun m -> m "package list: %s" e); []

  let by_names ?(init = String.Map.empty) pkgs =
    let add_pkg acc (n, _ as pkg) = String.Map.add n pkg acc in
    List.fold_left add_pkg init pkgs
end

module Doc_cobj = struct
  type kind = Cmi | Cmti | Cmt
  type t =
    { path : Fpath.t;
      kind : kind;
      modname : string;
      hidden : bool;
      pkg : Pkg.t; }

  let path cobj = cobj.path
  let kind cobj = cobj.kind
  let modname cobj = cobj.modname
  let pkg cobj = cobj.pkg
  let hidden cobj = cobj.hidden
  let don't_list cobj =
    hidden cobj || String.is_infix ~affix:"__" (modname cobj)

  let add_cobj pkg _ _ path acc =
    try
      let multi = true in (* implies e.g .p.ext objects are not considered *)
      let base, kind = match Fpath.cut_ext ~multi path with
      | base, ".cmi" -> base, Cmi
      | base, ".cmti" -> base, Cmti
      | base, ".cmt" -> base, Cmt
      | base, _ -> raise_notrace Exit
      in
      let modname = String.Ascii.capitalize (Fpath.basename base) in
      let cobj = match Fpath.Map.find base acc with
      | exception Not_found ->
          let hidden = not (kind = Cmi) in
          { path; kind; modname; hidden; pkg; }
      | cobj' ->
          match cobj'.kind, kind with
          | Cmi, (Cmti | Cmt) -> { path; kind; modname; hidden = false; pkg;  }
          | (Cmti | Cmt), Cmi -> { cobj' with hidden = false }
          | Cmt, Cmti -> { path; kind; modname; hidden = cobj'.hidden; pkg }
          | Cmti, Cmt | _ -> cobj'
      in
      Fpath.Map.add base cobj acc
    with Exit -> acc

  let of_pkg pkg =
    let dir = Pkg.path pkg in
    let recurse = true in
    let cobjs = Os.Dir.fold_files ~recurse (add_cobj pkg) dir Fpath.Map.empty in
    let cobjs = Log.if_error ~use:Fpath.Map.empty cobjs in
    Fpath.Map.fold (fun _ c acc -> c :: acc) cobjs []

  let by_modname ?(init = String.Map.empty) cobjs =
    let add acc cobj = match String.Map.find cobj.modname acc with
    | exception Not_found -> String.Map.add cobj.modname [cobj] acc
    | cobjs -> String.Map.add cobj.modname (cobj :: cobjs) acc
    in
    List.fold_left add init cobjs
end

module Opam = struct

  (* opam metadata *)

  type t = (string * string) list

  let unescape s = s (* TODO *)
  let parse_string = function
  | "" -> ("", "")
  | s ->
      match String.index s '"' with
      | exception Not_found -> (s, "")
      | i ->
          let start = i + 1 in
          let rec find_end i = match String.index_from s i '"' with
          | exception Not_found -> (s, "") (* unreported error ... *)
          | j when s.[j - 1] = '\\' -> find_end (j + 1)
          | j ->
              let stop = j - 1 in
              let str = String.sub s start (stop - start + 1) in
              let rest = String.sub s (j + 1) (String.length s - (j + 1)) in
              (unescape str, rest)
          in
          find_end start

  let parse_list s =
    if s = "" then [] else
    let rec loop acc s =
      let s, rest = parse_string s in
      let rest = String.trim rest in
      if rest = "" || rest = "]" then List.rev (s :: acc) else
      loop (s :: acc) rest
    in
    loop [] s

  let string_field f fields = match List.assoc f fields with
  | exception Not_found -> "" | v -> fst @@ parse_string v

  let list_field ?(sort = true) f fields = match List.assoc f fields with
  | exception Not_found -> []
  | v when sort -> List.sort compare (parse_list v)
  | v -> parse_list v

  let authors = list_field "authors"
  let bug_reports = list_field "bug-reports"
  let depends fs = match List.assoc "depends" fs with
  | exception Not_found -> [] | v ->
      let delete_constraints s =
        let rec loop s = match String.index s '{' with
        | exception Not_found -> s
        | i ->
            match String.index s '}' with
            | exception Not_found -> s
            | j ->
                loop (String.sub s 0 i) ^
                loop (String.sub s (j + 1) (String.length s - (j + 1)))
        in
        loop s
      in
      List.sort compare @@ parse_list (delete_constraints v)

  let dev_repo = list_field "dev-repo"
  let doc = list_field "doc"
  let homepage = list_field "homepage"
  let license = list_field "license"
  let maintainer = list_field "maintainer"
  let synopsis = string_field "synopsis"
  let tags fs = List.rev_map String.Ascii.lowercase @@ list_field "tags" fs
  let version = string_field "version"

  (* Queries *)

  let file pkg =
    let opam = Fpath.(Pkg.path pkg / "opam") in
    match Os.File.exists opam |> Log.if_error ~use:false with
    | true -> Some opam
    | false -> None

  let bin = lazy begin
    Result.bind (Os.Cmd.must_find_tool (Fpath.v "opam")) @@ fun opam ->
    Result.bind (Os.Cmd.run_out Cmd.(path opam % "--version")) @@ fun v ->
    match String.cut_left ~sep:"." (String.trim v) with
    | Some (maj, _)  when
        maj <> "" && Char.code maj.[0] - 0x30 >= 2 -> Ok opam
    | Some _ | None ->
        Fmt.error "%a: unsupported version %s" Fpath.pp opam v
  end

  let fields =
    [ "name:"; "authors:"; "bug-reports:"; "depends:"; "dev-repo:"; "doc:";
      "homepage:"; "license:"; "maintainer:"; "synopsis:"; "tags:";
      "version:" ]

  let field_count = List.length fields
  let field_arg = Fmt.str "--field=%s" (String.concat "," fields)
  let rec take_fields n acc lines = match n with
  | 0 -> acc, lines
  | n ->
      match lines with
      | [] -> [], [] (* unreported error... *)
      | l :: ls ->
          match String.cut_left ~sep:":" l with
          | None -> [], [] (* unreported error... *)
          | Some (f, v) -> take_fields (n - 1) ((f, String.trim v) :: acc) ls

  let rec parse_lines acc = function
  | [] -> acc
  | name :: lines ->
      let err l =
        Log.err (fun m -> m "%S: opam metadata expected name: field line" l)
      in
      match String.cut_left ~sep:":" name with
      | Some ("name", n) ->
          let n, _ = parse_string n in
          let fields, lines = take_fields (field_count - 1) [] lines in
          parse_lines (String.Map.add n fields acc) lines
      | None | Some _ -> err name; acc

  let query qpkgs =
    (* opam show (at least until v2.0.3) returns results in package
       name order which is too easy to get confused about (we need to
       precisely know how opam orders and apparently we do not). So we
       also query for the name: field first and rebind the data to packages
       after parsing. *)
    let pkgs = Pkg.Set.of_list qpkgs in
    let add_opam p acc = match file p with None -> acc | Some f -> f :: acc in
    let opams = Pkg.Set.fold add_opam pkgs [] in
    let no_data pkgs = List.map (fun p -> (p, [])) pkgs in
    match Lazy.force bin with
    | Error e -> Log.err (fun m -> m "%s" e); no_data qpkgs
    | Ok opam ->
        if opams = [] then no_data qpkgs else
        let show = Cmd.(path opam % "show" % "--normalise" % "--no-lint") in
        let show = Cmd.(show % field_arg %% paths opams) in
        match
          Log.time (fun _ m -> m "opam show") @@ fun () ->
          let stderr = `Stdo (Os.Cmd.out_null) in
          Os.Cmd.run_out ~stderr show
        with
        | Error e -> Log.err (fun m -> m "%s" e); no_data qpkgs
        | Ok out ->
            let lines = String.cuts_left ~sep:"\n" out in
            let infos = parse_lines String.Map.empty lines in
            let find_info is p = match String.Map.find (Pkg.name p) is with
            | exception Not_found -> p, []
            | i -> p, i
            in
            try List.map (find_info infos) qpkgs with
            | Not_found -> assert false
end

module Docdir = struct

  (* Docdir info *)

  type files =
    { changes_files : Fpath.t list;
      license_files : Fpath.t list;
      readme_files : Fpath.t list; }

  type t =
    { dir : Fpath.t option;
      files : files Lazy.t;
      odoc_pages : Fpath.t list Lazy.t;
      odoc_assets_dir : Fpath.t option Lazy.t;
      odoc_assets : Fpath.t list Lazy.t; }

  let docdir_files pkg_docdir =
    let cs, ls, rs = match pkg_docdir with
    | None -> [], [], []
    | Some docdir ->
        let add_file _ base file (cs, ls, rs as acc) =
          let base = String.uppercase_ascii base in
          let is_pre pre = String.is_prefix pre base in
          if is_pre "CHANGE" || is_pre "HISTORY" || is_pre "NEWS"
          then (file :: cs), ls, rs else
          if is_pre "LICENSE" then cs, (file :: ls), rs else
          if is_pre "README" then cs, ls, (file :: rs) else
          acc
        in
        Os.Dir.fold_files ~recurse:false add_file docdir ([], [], [])
        |> Log.if_error ~use:([], [], [])
    in
    let changes_files = List.sort Fpath.compare cs in
    let license_files = List.sort Fpath.compare ls in
    let readme_files = List.sort Fpath.compare rs in
    { changes_files; license_files; readme_files }

  let docdir_subdir_files pkg_docdir sub ~sat = match pkg_docdir with
  | None -> []
  | Some pkg_docdir ->
      let dir = Fpath.(pkg_docdir / sub) in
      match Os.Dir.exists dir with
      | Ok false | Error _  -> []
      | Ok true ->
          let add_file = match sat with
          | None -> fun _ _ file acc -> file :: acc
          | Some sat ->
              fun _ _ file acc -> if sat file then file :: acc else acc
          in
          Os.Dir.fold_files ~recurse:true add_file dir []
          |> Log.if_error ~use:[]

  let docdir_odoc_pages pkg_docdir =
    let is_mld = Some (Fpath.has_ext ".mld") in
    docdir_subdir_files pkg_docdir "odoc-pages" ~sat:is_mld

  let docdir_odoc_assets pkg_docdir  =
    docdir_subdir_files pkg_docdir "odoc-assets" ~sat:None

  let docdir_odoc_assets_dir pkg_docdir = match pkg_docdir with
  | None -> None
  | Some pkg_docdir ->
      let dir = Fpath.(pkg_docdir / "odoc-assets") in
      match Os.Dir.exists dir |> Log.if_error ~use:false with
      | false -> None
      | true -> Some dir

  let v pkg_docdir =
    let files = lazy (docdir_files pkg_docdir) in
    let odoc_pages = lazy (docdir_odoc_pages pkg_docdir) in
    let odoc_assets_dir = lazy (docdir_odoc_assets_dir pkg_docdir) in
    let odoc_assets = lazy (docdir_odoc_assets pkg_docdir) in
    { dir = pkg_docdir; files; odoc_pages; odoc_assets_dir; odoc_assets }

  let dir i = i.dir
  let changes_files i = (Lazy.force i.files).changes_files
  let license_files i = (Lazy.force i.files).license_files
  let odoc_pages i = Lazy.force i.odoc_pages
  let odoc_assets_dir i = Lazy.force i.odoc_assets_dir
  let odoc_assets i = Lazy.force i.odoc_assets
  let readme_files i = (Lazy.force i.files).readme_files
  let of_pkg ~docdir pkg =
    let docdir = Fpath.(docdir / Pkg.name pkg) in
    match Os.Dir.exists docdir |> Log.if_error ~use:false with
    | true -> v (Some docdir)
    | false -> v None
end

module Pkg_info = struct
  type t =
    { doc_cobjs : Doc_cobj.t list Lazy.t;
      opam : Opam.t;
      docdir : Docdir.t Lazy.t }

  let doc_cobjs i = Lazy.force i.doc_cobjs
  let opam i = i.opam
  let docdir i = Lazy.force i.docdir

  type field =
  [ `Authors | `Changes_files | `Doc_cobjs | `Depends | `Homepage | `Issues
  | `License | `License_files | `Maintainers | `Odoc_assets | `Odoc_pages
  | `Online_doc | `Readme_files | `Repo | `Synopsis | `Tags | `Version ]

  let field_names =
    [ "authors", `Authors; "changes-files", `Changes_files;
      "depends", `Depends; "doc-cobjs", `Doc_cobjs;
      "homepage", `Homepage; "issues", `Issues; "license", `License;
      "license-files", `License_files; "maintainers", `Maintainers;
      "odoc-assets", `Odoc_assets; "odoc-pages", `Odoc_pages;
      "online-doc", `Online_doc; "readme-files", `Readme_files;
      "repo", `Repo; "synopsis", `Synopsis; "tags", `Tags;
      "version", `Version; ]

  let get field i =
    let paths ps = List.map Fpath.to_string ps in
    match field with
    | `Authors -> Opam.authors (opam i)
    | `Changes_files -> paths @@ Docdir.changes_files (docdir i)
    | `Depends -> Opam.depends (opam i)
    | `Doc_cobjs -> paths @@ List.map Doc_cobj.path (doc_cobjs i)
    | `Homepage -> Opam.homepage (opam i)
    | `Issues -> Opam.bug_reports (opam i)
    | `License -> Opam.license (opam i)
    | `License_files -> paths @@ Docdir.license_files (docdir i)
    | `Maintainers -> Opam.maintainer (opam i)
    | `Odoc_assets -> paths @@ Docdir.odoc_assets (docdir i)
    | `Odoc_pages -> paths @@ Docdir.odoc_pages (docdir i)
    | `Online_doc -> Opam.doc (opam i)
    | `Readme_files -> paths @@ Docdir.readme_files (docdir i)
    | `Repo -> Opam.dev_repo (opam i)
    | `Synopsis -> (match Opam.synopsis (opam i) with "" -> [] | s -> [s])
    | `Tags -> Opam.tags (opam i)
    | `Version -> (match Opam.version (opam i) with "" -> [] | s -> [s])

  let pp ppf i =
    let pp_value = Fmt.(hvbox @@ list ~sep:sp string) in
    let pp_field ppf (n, f) = Fmt.field n pp_value ppf (get f i) in
    let pp_field ppf spec = Fmt.pf ppf "| %a" pp_field spec in
    Fmt.pf ppf "@[<v>%a@]" (Fmt.list pp_field) field_names

  (* Queries *)

  let query ~docdir pkgs =
    let rec loop acc = function
    | [] -> List.rev acc
    | (p, opam) :: ps ->
        let doc_cobjs = lazy (Doc_cobj.of_pkg p) in
        let docdir = lazy (Docdir.of_pkg ~docdir p) in
        loop ((p, {doc_cobjs; opam; docdir}) :: acc) ps
    in
    loop [] (Opam.query pkgs)
end

module Conf = struct
  let in_prefix_path dir =
    let exec = Fpath.of_string Sys.executable_name |> Result.to_failure in
    Fpath.((parent @@ parent @@ exec) // dir)

  let get_dir default_dir var = function
  | Some dir -> dir
  | None ->
      match Os.Env.find ~empty_to_none:true var with
      | Some l -> Fpath.of_string l |> Result.to_failure
      | None -> in_prefix_path default_dir

  let cachedir_env = "ODIG_CACHEDIR"
  let get_cachedir dir = get_dir Fpath.(v "var/cache/odig") cachedir_env dir

  let libdir_env = "ODIG_LIBDIR"
  let get_libdir dir = get_dir (Fpath.v "lib") libdir_env dir

  let docdir_env = "ODIG_DOCDIR"
  let get_docdir dir = get_dir (Fpath.v "doc") docdir_env dir

  let sharedir_env = "ODIG_SHAREDIR"
  let get_sharedir dir = get_dir (Fpath.v "share") sharedir_env dir

  let odoc_theme_env = "ODIG_ODOC_THEME"
  let get_odoc_theme = function
  | Some v -> v
  | None ->
      match Os.Env.find ~empty_to_none:true odoc_theme_env with
      | Some t -> t
      | None -> B0_odoc.Theme.get_user_preference () |> Result.to_failure

  let file_cache_dir cache_dir = Fpath.(cache_dir / "memo")
  let trash_dir cache_dir = Fpath.(cache_dir / "trash")
  let memo cdir ~max_spawn =
    let cache_dir = file_cache_dir cdir in
    let trash_dir = trash_dir cdir in
    lazy begin
      let max_spawn = B0_ui.Memo.max_spawn ~jobs:max_spawn () in
      let feedback =
        let show_spawn_ui = Log.Info in
        let show_success = Log.Debug in
        B0_ui.Memo.log_feedback ~show_spawn_ui ~show_success Fmt.stderr
      in
      Memo.memo ~max_spawn ~feedback ~cache_dir ~trash_dir ()
    end

  type t =
    { cachedir : Fpath.t;
      libdir : Fpath.t;
      docdir : Fpath.t;
      sharedir : Fpath.t;
      htmldir : Fpath.t;
      odoc_theme : string;
      memo : (Memo.t, string) result Lazy.t;
      pkgs : Pkg.t list Lazy.t;
      pkg_infos : Pkg_info.t Pkg.Map.t Lazy.t; }

  let v ?cachedir ?libdir ?docdir ?sharedir ?odoc_theme ~max_spawn () =
    try
      let cachedir = get_cachedir cachedir in
      let libdir = get_libdir libdir in
      let docdir = get_docdir docdir in
      let sharedir = get_sharedir sharedir in
      let htmldir = Fpath.(cachedir / "html") in
      let odoc_theme = get_odoc_theme odoc_theme in
      let memo = memo cachedir ~max_spawn in
      let pkgs = lazy (Pkg.of_dir libdir) in
      let pkg_infos = Lazy.from_fun @@ fun () ->
        let add acc (p, i) = Pkg.Map.add p i acc in
        let pkg_infos = Pkg_info.query docdir (Lazy.force pkgs) in
        List.fold_left add Pkg.Map.empty pkg_infos
      in
      Ok { cachedir; libdir; docdir; sharedir; htmldir; odoc_theme; memo; pkgs;
           pkg_infos }
    with
    | Failure e -> Fmt.error "conf: %s" e

  let cachedir c = c.cachedir
  let libdir c = c.libdir
  let docdir c = c.docdir
  let sharedir c = c.sharedir
  let htmldir c = c.htmldir
  let odoc_theme c = c.odoc_theme
  let pp ppf c =
    Fmt.pf ppf "@[<v>";
    Fmt.field "cachedir" Fpath.pp ppf c.cachedir; Fmt.cut ppf ();
    Fmt.field "docdir" Fpath.pp ppf c.docdir; Fmt.cut ppf ();
    Fmt.field "libdir" Fpath.pp ppf c.libdir; Fmt.cut ppf ();
    Fmt.field "odoc-theme" Fmt.string ppf c.odoc_theme; Fmt.cut ppf ();
    Fmt.field "sharedir" Fpath.pp ppf c.sharedir;
    Fmt.pf ppf "@]"

  let memo c = Lazy.force c.memo
  let file_cache_dir c = file_cache_dir c.cachedir
  let pkgs c = Lazy.force c.pkgs
  let pkg_infos c = Lazy.force c.pkg_infos
end

(*---------------------------------------------------------------------------
   Copyright (c) 2018 The odig programmers

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
