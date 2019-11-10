(*---------------------------------------------------------------------------
   Copyright (c) 2018 The odig programmers. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open B0_std
open Odig_support

(* Return codes and error handling *)

let err_name = 1
let err_uri = 2
let err_some = 3

let handle_error code v f = match v with
| Error e -> Log.err (fun m -> m "%a" Fmt.lines e); code
| Ok v -> f v

let handle_name_error v f = handle_error err_name v f
let handle_some_error v f = handle_error err_some v f
let handle_pager no_pager f =
  handle_error err_some (B0_pager.find ~don't:no_pager ()) f

let handle_stdout_paging no_pager f =
  handle_pager no_pager @@ fun pager ->
  handle_error err_some (B0_pager.page_stdout pager) f

let handle_browser browser f =
  handle_error err_some (B0_www_browser.find ~browser ()) f

(* Commonalities *)

let find_pkgs conf = function
| [] -> Ok (Conf.pkgs conf)
| ns ->
    let pkgs = Conf.pkgs conf in
    let by_name = Pkg.by_names pkgs in
    let add_name (fnd, miss) n = match String.Map.find n by_name with
    | exception Not_found -> (fnd, n :: miss)
    | pkg -> (pkg :: fnd, miss)
    in
    let fnd, miss = List.fold_left add_name ([], []) ns in
    match miss with
    | [] -> Ok (List.rev fnd)
    | miss ->
        let exists = List.rev_map Pkg.name pkgs in
        let add_error acc n =
          let kind = Fmt.any "package" in
          let unknown = Fmt.(unknown' ~kind Fmt.string ~hint:did_you_mean) in
          let err = Fmt.str "%a" unknown (n, String.suggest exists n) in
          err :: acc
        in
        Error (String.concat "\n" (List.fold_left add_error [] miss))

let odoc_gen conf ~force ~index_title ~index_intro ~pkg_deps ~tag_index pkgs =
  Log.app (fun m -> m "Updating documentation, this may take some time...");
  Odig_odoc.gen conf ~force ~index_title ~index_intro ~pkg_deps ~tag_index pkgs

(* Commands *)

let browse_cmd conf background browser field pkg_names =
  handle_name_error (find_pkgs conf pkg_names) @@ fun pkgs ->
  handle_browser browser @@ fun browser ->
  let get_uris = match field with
  | `Homepage -> Opam.homepage
  | `Issues -> Opam.bug_reports
  | `Online_doc -> Opam.doc
  in
  let pkgs = Opam.query pkgs in
  let uris = List.concat (List.map (fun (_, o) -> get_uris o) pkgs) in
  let rec loop exit = function
  | [] -> exit
  | u :: us ->
      match B0_www_browser.show ~background ~prefix:false browser u with
      | Error e -> Log.err (fun m -> m "%s" e); loop err_uri us
      | Ok () -> loop exit us
  in
  loop 0 uris

let conf_cmd conf = Fmt.pr "%a@." Conf.pp conf; 0
let cache_cmd conf = function
| `Path -> Fmt.pr "%a@." Fpath.pp_unquoted (Conf.cache_dir conf); 0
| `Clear ->
    let dir = Conf.cache_dir conf in
    Log.app begin fun m ->
      m "Deleting %a, this may take some time..."
        (Fmt.tty [`Fg `Green] Fpath.pp_quoted) dir
    end;
    let del = Os.Path.delete ~recurse:true dir in
    Log.if_error ~use:err_some (Result.bind del @@ fun _ -> Ok 0)
| `Trim ->
    let b0_cache_dir = Conf.b0_cache_dir conf in
    Log.if_error ~use:err_some @@
    Result.bind (Os.Dir.exists b0_cache_dir) @@ function
    | false -> Ok 0
    | true ->
        let pct = 50 and max_byte_size = max_int in
        Result.bind (B000.File_cache.create b0_cache_dir) @@ fun c ->
        Result.bind (B000.File_cache.trim_size c ~max_byte_size ~pct) @@
        fun () -> Ok 0

let doc_cmd conf background browser pkg_names update no_update show_files =
  let pkgs = match pkg_names with
  | [] -> Ok []
  | ns -> find_pkgs conf pkg_names
  in
  let exists f = Os.File.exists f |> Log.if_error ~use:false in
  handle_browser browser @@ fun browser ->
  handle_name_error pkgs @@ fun pkgs ->
  let prepare_files = match pkgs with
  | [] ->
      let root_index = Fpath.(Conf.html_dir conf / "index.html") in
      begin match exists root_index with
      | true when not update || no_update -> Ok [root_index]
      | false when no_update -> Error "No doc found. Try with 'odig doc -u'."
      | _ ->
          let pkgs = Conf.pkgs conf in
          let index_title = None and index_intro = None in
          let force = false and pkg_deps = true and tag_index = true in
          Result.bind
            (odoc_gen conf ~force ~index_title ~index_intro ~pkg_deps
               ~tag_index pkgs)
            (fun () -> Ok [root_index])
      end
  | pkgs ->
      let index conf pkg =
        Fpath.(Conf.html_dir conf / Pkg.name pkg / "index.html")
      in
      let files = List.rev (List.rev_map (index conf) pkgs) in
      let does_not_exist = List.find_all (fun f -> not (exists f)) files in
      match does_not_exist with
      | [] when not update || no_update -> Ok files
      | files when no_update ->
          Fmt.error
            "@[<v>No doc found for:@, %a@,@[Try with 'odig doc -u %a'@]@]"
            Fmt.(list Fpath.pp_quoted) files
            Fmt.(list Pkg.pp_name) pkgs
      | _ ->
          let index_title = None and index_intro = None in
          let force = false and pkg_deps = true and tag_index = true in
          Result.bind
            (odoc_gen conf ~force ~index_title ~index_intro ~pkg_deps
               ~tag_index pkgs)
            (fun () -> Ok files)
  in
  Log.if_error ~use:err_some @@
  Result.bind prepare_files @@ fun files ->
  let does_not_exist = List.find_all (fun f -> not (exists f)) files in
  match does_not_exist with
  | [] when show_files ->
      Fmt.pr "@[<v>%a@]@." (Fmt.list Fpath.pp_quoted) files; Ok 0
  | [] ->
      let rec loop exit = function
      | [] -> Ok exit
      | f :: fs ->
          let file_uri p = Fmt.str "file://%a" Fpath.pp_unquoted p in
          let u = file_uri f in
          match B0_www_browser.show ~background ~prefix:false browser u with
          | Error e -> Log.err (fun m -> m "%s" e); loop err_uri fs
          | Ok () -> loop exit fs
      in
      loop 0 files
  | fs ->
      Fmt.error "@[<v>No doc could be generated for:@,%a@]"
        (Fmt.list Fpath.pp_quoted) fs

let log_cmd conf no_pager format kind op_selector =
  Log.if_error ~use:err_some @@
  let don't = no_pager || format = `Trace_event in
  Result.bind (B0_pager.find ~don't ()) @@ fun pager ->
  Result.bind (B0_pager.page_stdout pager) @@ fun () ->
  let log_file = Conf.b0_log_file conf in
  Result.bind (B00_ui.Memo.Log.read log_file) @@ fun l ->
  B00_ui.Memo.Log.out Fmt.stdout format kind op_selector ~path:log_file l;
  Ok 0

let odoc_cmd
    conf _odoc pkg_names index_title index_intro force no_pkg_deps no_tag_index
  =
  let pkg_deps = not no_pkg_deps in
  let tag_index = not no_tag_index in
  handle_name_error (find_pkgs conf pkg_names) @@ fun pkgs ->
  handle_some_error
    (odoc_gen conf ~force ~index_title ~index_intro ~pkg_deps ~tag_index pkgs)
  @@ fun () -> 0

let odoc_theme_cmd conf out_fmt action theme set_default =
  let list_themes conf out_fmt =
    match B0_odoc.Theme.of_dir (Conf.share_dir conf) with
    | [] -> 0
    | ts ->
        let pp_theme = function
        | `Short -> B0_odoc.Theme.pp_name
        | `Normal | `Long -> B0_odoc.Theme.pp
        in
        Fmt.pr "@[<v>%a@]@." (Fmt.list (pp_theme out_fmt)) ts; 0
  in
  let default conf =
    let ts = B0_odoc.Theme.of_dir (Conf.share_dir conf) in
    let theme = Conf.odoc_theme conf in
    Fmt.pr "%s@." theme;
    match B0_odoc.Theme.find theme ts with
    | Error e -> Log.warn (fun m -> m "%s" e); err_name
    | Ok _ -> 0
  in
  let set_theme conf theme set_default =
    let ts = B0_odoc.Theme.of_dir (Conf.share_dir conf) in
    let theme = match theme with None -> Conf.odoc_theme conf | Some t -> t in
    match B0_odoc.Theme.find theme ts with
    | Error e -> Log.err (fun m -> m "%s" e); err_name
    | Ok t ->
        handle_some_error (Odig_odoc.set_theme conf t) @@ fun () ->
        match set_default with
        | false -> 0
        | true ->
            let name = B0_odoc.Theme.name t in
            handle_some_error (B0_odoc.Theme.set_user_preference name) @@
            fun () -> 0
  in
  let path conf theme =
    let ts = B0_odoc.Theme.of_dir (Conf.share_dir conf) in
    let theme = match theme with None -> Conf.odoc_theme conf | Some t -> t in
    match B0_odoc.Theme.find theme ts with
    | Error e -> Log.err (fun m -> m "%s" e); err_name
    | Ok t -> Fmt.pr "%a@." Fpath.pp_unquoted (B0_odoc.Theme.path t); 0
  in
  match action with
  | `List -> list_themes conf out_fmt
  | `Default -> default conf
  | `Set -> set_theme conf theme set_default
  | `Path -> path conf theme

let pkg_cmd conf no_pager out_fmt pkg_names =
  handle_name_error (find_pkgs conf pkg_names) @@ fun pkgs ->
  handle_stdout_paging no_pager @@ fun () ->
  let pp_pkgs = match out_fmt with
  | `Short -> (fun ppf () -> (Fmt.list Pkg.pp_name) ppf pkgs)
  | `Normal ->
      let pp_pkg ppf (pkg, o) =
        Fmt.pf ppf "@[<h>%a %a %a@]"
          Pkg.pp_name pkg Pkg.pp_version (Opam.version o)
          (Fmt.tty [`Faint] Fpath.pp_quoted) (Pkg.path pkg)
      in
      let pkgs = Opam.query pkgs in
      (fun ppf () -> (Fmt.list pp_pkg) ppf pkgs)
  | `Long ->
      let pp_pkg ppf (pkg, i) =
        Fmt.pf ppf "@[<v>%a@,%a@]" Pkg.pp pkg Pkg_info.pp i
      in
      let pkgs = Pkg_info.query ~doc_dir:(Conf.doc_dir conf) pkgs in
      (fun ppf () -> (Fmt.list pp_pkg) ppf pkgs)
  in
  Fmt.pr "@[<v>%a@]@." pp_pkgs (); 0

let show_cmd conf no_pager out_fmt show_empty field pkg_names =
  handle_name_error (find_pkgs conf pkg_names) @@ fun pkgs ->
  handle_stdout_paging no_pager @@ fun () ->
  let pp_field field out_fmt show_empty = match out_fmt with
  | `Short | `Normal ->
      (fun ppf (p, i) -> match Pkg_info.get field i with
        | [] -> if show_empty then Fmt.pf ppf "@," else ()
        | vs -> Fmt.pf ppf "%a@," Fmt.(list string) vs)
  | `Long ->
      (fun ppf (p, i) -> match Pkg_info.get field i with
        | [] when not show_empty -> ()
        | [] -> Fmt.pf ppf "@[<h>%a@]@," Pkg.pp_name p
        | vs ->
            let pp_val ppf v = Fmt.pf ppf "@[<h>%a %s@]" Pkg.pp_name p v in
            Fmt.pf ppf "%a@," Fmt.(list pp_val) vs)
  in
  let infos = Pkg_info.query ~doc_dir:(Conf.doc_dir conf) pkgs in
  let pp_field = pp_field field out_fmt show_empty in
  Fmt.pr "@[<v>%a@]@?" Fmt.(list ~sep:Fmt.nop pp_field) infos;
  0

let show_files_cmd conf no_pager pkg_names get_files =
  handle_name_error (find_pkgs conf pkg_names) @@ fun pkgs ->
  handle_pager no_pager @@ fun pager ->
  let doc_dir = Conf.doc_dir conf in
  let doc_dirs = List.map (fun p -> p, (Doc_dir.of_pkg ~doc_dir p)) pkgs in
  let files = List.concat (List.map (fun (p, i) -> get_files i) doc_dirs) in
  handle_error err_some (B0_pager.page_files pager files) @@ fun () -> 0

(* Command line interface *)

open Cmdliner

(* Arguments and commonalities *)

let exits =
  Term.exit_info err_name ~doc:"a specified entity name cannot be found." ::
  Term.exit_info err_uri ~doc:"an URI cannot be shown in a browser." ::
  Term.exit_info err_some ~doc:"indiscriminate error reported on stderr." ::
  Term.default_exits

let details = B00_ui.Cli.out_details ()
let conf =
  let path = B0_std_ui.fpath in
  let docs = Manpage.s_common_options in
  let docv = "PATH" in
  let doc dirname dir =
    Fmt.str
    "%s directory. If unspecified, $(b,\\$PREFIX)/%s with $(b,\\$PREFIX) \
     the parent directory of $(mname)'s install directory." dirname dir
  in
  let b0_std_setup =
    (* FIXME do it b0caml like *)
    let color_env = Arg.env_var "ODIG_COLOR" in
    let verbosity_env = Arg.env_var "ODIG_VERBOSITY" in
    let tty_cap = B0_std_ui.tty_cap ~env:color_env () in
    let log_level = B0_std_ui.log_level ~env:verbosity_env () in
    let conf tty_cap log_level =
      let tty_cap = B0_std_ui.get_tty_cap tty_cap in
      let log_level = B0_std_ui.get_log_level log_level in
      B0_std_ui.setup tty_cap log_level ~log_spawns:Log.Debug
    in
    Term.(pure conf $ tty_cap $ log_level)
  in
  let b0_cache_dir =
    let env = Arg.env_var "ODIG_B0_CACHE_DIR" in
    let doc_none = "$(b,.cache) in odig cache directory" in
    B00_ui.Memo.cache_dir ~opts:["b0-cache-dir"] ~doc_none ~env ()
  in
  let b0_log_file =
    let env = Arg.env_var "ODIG_B0_LOG_FILE" in
    let doc_none = "$(b,.log) in odig cache directory" in
    B00_ui.Memo.log_file ~doc_none ~env ()
  in
  let cache_dir =
    let doc = doc "Cache" "var/cache/odig" in
    let env = Arg.env_var Conf.cache_dir_env in
    Arg.(value & opt (some path) None & info ["cache-dir"] ~doc ~docs ~env
           ~docv)
  in
  let doc_dir =
    let doc = doc "Documentation" "doc" in
    let env = Arg.env_var Conf.doc_dir_env in
    Arg.(value & opt (some path) None & info ["doc-dir"] ~doc ~docs ~env ~docv)
  in
  let lib_dir =
    let doc = doc "Library" "lib" in
    let env = Arg.env_var Conf.lib_dir_env in
    Arg.(value & opt (some path) None & info ["lib-dir"] ~doc ~docs ~env ~docv)
  in
  let jobs = B00_ui.Memo.jobs ~docs ~env:(Arg.env_var "ODIG_JOBS") () in
  let odoc_theme =
    let doc =
      "Theme to use for odoc documentation. If unspecified, the theme can be \
       specified in the file $(b,~/.config/odig/odoc-theme) or \
       $(b,odoc.default) is used."
    in
    let env = Arg.env_var Conf.odoc_theme_env in
    Arg.(value & opt (some string) None &
         info ["odoc-theme"] ~doc ~docs ~env ~docv:"THEME")
  in
  let share_dir =
    let doc = doc "Share" "share" in
    let env = Arg.env_var Conf.share_dir_env in
    Arg.(value & opt (some path) None & info ["share-dir"] ~doc ~docs ~env
           ~docv)
  in
  let conf
      () b0_cache_dir b0_log_file cache_dir doc_dir jobs lib_dir odoc_theme
      share_dir
    =
    Result.map_error (fun s -> `Msg s) @@
    Conf.v ~b0_cache_dir ~b0_log_file ~cache_dir ~doc_dir ~jobs ~lib_dir
      ~odoc_theme ~share_dir ()
  in
  Term.term_result @@
  Term.(const conf $ b0_std_setup $ b0_cache_dir $ b0_log_file $ cache_dir $
        doc_dir $ jobs $ lib_dir $ odoc_theme $ share_dir)

let pkgs_pos1_nonempty, pkgs_pos, pkgs_pos1, pkgs_opt =
  let doc = "Package to consider (repeatable)." in
  let docv = "PKG" in
  Arg.(non_empty & pos_right 0 string [] & info [] ~doc ~docv),
  Arg.(value & pos_all string [] & info [] ~doc ~docv),
  Arg.(value & pos_right 0 string [] & info [] ~doc ~docv),
  Arg.(value & opt_all string [] & info ["p"; "pkg"] ~doc ~docv)

let background = B0_www_browser.background ()
let browser = B0_www_browser.browser ()
let no_pager = B0_pager.don't ()

let show_files_cmd ?cmd ~kind get_files =
  let cname = match cmd with None -> kind | Some cmd -> cmd in
  let doc = Fmt.str "Show package %s files" kind in
  let sdocs = Manpage.s_common_options and man_xrefs = [ `Main ] in
  let envs = B0_pager.envs () in
  let man =
    [ `S "DESCRIPTION";
      `P (Fmt.str "The $(tname) command shows package %s files. If \
                   invoked with $(b,--no-pager) and multiple files are output \
                   these are separated by a U+001C (file separator) control \
                   character." kind);
      `P "To output the file paths rather than their content use $(mname) \
          $(b,show)." ]
  in
  Term.(const show_files_cmd $ conf $ no_pager $ pkgs_pos $ const get_files),
  Term.info cname ~doc ~sdocs ~envs ~exits ~man_xrefs ~man

(* Commands *)

let sdocs = Manpage.s_common_options

let browse_cmd =
  let doc = "Open package metadata URIs in your browser" in
  let man_xrefs = [ `Main ] in
  let man = [
    `S Manpage.s_description;
    `P "$(tname) command opens or reloads metadata URI fields of packages
        in a WWW browser." ]
  in
  let field =
    let field =
      [ "homepage", `Homepage; "issues", `Issues; "online-doc", `Online_doc; ]
    in
    let alts = Arg.doc_alts_enum field in
    let doc = Fmt.str "The URI field to show. $(docv) must be %s." alts in
    let action = Arg.enum field in
    Arg.(required & pos 0 (some action) None & info [] ~doc ~docv:"FIELD")
  in
  Term.(const browse_cmd $ conf $ background $ browser $ field $
        pkgs_pos1_nonempty),
  Term.info "browse" ~doc ~sdocs ~exits ~man ~man_xrefs

let cache_cmd =
  let doc = "Operate on the odig cache" and man_xrefs = [ `Main ] in
  let man = [
    `S Manpage.s_synopsis;
    `P "$(mname) $(tname) $(i,ACTION) [$(i,OPTION)]...";
    `S Manpage.s_description;
    `P "The $(tname) command operates on the odig cache. See the available
        actions below.";
    `S "ACTIONS";
    `I ("$(b,path)", "Display the path to the cache");
    `I ("$(b,clear)", "Clear the cache");
    `I ("$(b,trim)", "Trim the b0 cache (doesn't affect generated docs)"); ]
  in
  let action =
    let action = [ "path", `Path; "clear", `Clear; "trim", `Trim ] in
    let doc = Fmt.str "The action to perform. $(docv) must be one of %s."
        (Arg.doc_alts_enum action)
    in
    let action = Arg.enum action in
    Arg.(required & pos 0 (some action) None & info [] ~doc ~docv:"ACTION")
  in
  Term.(const cache_cmd $ conf $ action),
  Term.info "cache" ~doc ~sdocs ~exits ~man ~man_xrefs

let changes_cmd =
  show_files_cmd ~cmd:"changes" ~kind:"change log" Doc_dir.changes_files

let conf_cmd =
  let doc = "Show odig configuration" and man_xrefs = [ `Main ] in
  let man = [
    `S Manpage.s_description;
    `P "$(tname) outputs the odig configuration.";
    `P "$(mname) needs to know the path to the library directory, the
        path to the documentation directory, the path to the share
        directory and the path to the odig cache.";
    `P "Each can be specified on the command line or via an environment
        variable. If none of this is done they are determined relative
        to the binary's install directory. See the options $(b,--lib-dir),
        $(b,--doc-dir), $(b,--share-dir) and $(b,--cache-dir) for details."; ]
  in
  Term.(const conf_cmd $ conf),
  Term.info "conf" ~doc ~sdocs ~exits ~man ~man_xrefs

let doc_cmd =
  let doc = "Show odoc API documentation and manuals" in
  let man_xrefs = [ `Main; `Cmd "odoc" ] in
  let man = [
    `S Manpage.s_description;
    `P "$(tname) shows API documentation and manuals as generated
        by $(mname) $(b,odoc)."; ]
  in
  let update =
    let doc =
      "Make sure docs for the request are up-to-date. This happens \
       automatically if part of the request cannot be found, use \
       $(b,--no-update) to prevent this."
    in
    Arg.(value & flag & info ["u"; "update"] ~doc)
  in
  let no_update =
    let doc = "Never try to update the docs. Takes over $(b,--update)." in
    Arg.(value & flag & info ["n"; "no-update"] ~doc)
  in
  let show_files =
    let doc =
      "Output files on stdout one by line, rather than trying to open them \
       in a broken way."
    in
    Arg.(value & flag & info ["f"; "show-files"] ~doc)
  in
  Term.(const doc_cmd $ conf $ background $ browser $ pkgs_pos $ update $
        no_update $ show_files),
  Term.info "doc" ~doc ~sdocs ~exits ~man ~man_xrefs

let license_cmd =
  show_files_cmd ~kind:"license" Doc_dir.license_files

let odoc_cmd =
  let doc = "Generate odoc API documentation and manuals" in
  let man_xrefs = [ `Main ] in
  let man = [
    `S Manpage.s_description;
    `P "$(tname) generates the odoc API documentation and manual of packages.";
    `P "See the packaging conventions in $(mname) $(b,doc) $(mname) for
        generation details."; ]
  in
  let odoc = Term.const "odoc"
(* let doc = "The odoc command to use." in
    let env = Arg.env_var "ODIG_ODOC" in
    Arg.(value & opt string "odoc" & info ["odoc"] ~env ~docv:"CMD" ~doc) *)
  in
  let force = Term.const false
    (* let doc = "Force generation even if files are up-to-date." in
    Arg.(value & flag & info ["f"; "force"] ~doc) *)
  in
  let index_title =
    let doc = "$(docv) is the title of the package list page." in
    let docv = "TITLE" in
    Arg.(value & opt (some string) None & info ["index-title"] ~docv ~doc)
  in
  let index_intro =
    let doc = "$(docv) is the .mld file to use to define the introduction
               text on the package list page."
    in
    let some_path = Arg.some B0_std_ui.fpath in
    Arg.(value & opt some_path None & info ["index-intro"] ~docv:"MLDFILE" ~doc)
  in
  let no_pkg_deps =
    let doc = "Restrict documentation generation to the packages mentioned \
               on the command line, their dependencies are not automatically \
               included in the result. Note that this may lead to broken \
               links in the documentation set."
    in
    Arg.(value & flag & info ["no-pkg-deps"] ~doc)
  in
  let no_tag_index =
    let doc = "Do not generate the tag index on the package list page." in
    Arg.(value & flag & info ["no-tag-index"] ~doc)
  in
  Term.(const odoc_cmd $ conf $ odoc $ pkgs_pos $ index_title $ index_intro $
        force $ no_pkg_deps $ no_tag_index),
  Term.info "odoc" ~doc ~sdocs ~exits ~man ~man_xrefs

let odoc_theme_cmd =
  let doc = "Manage themes for odoc API and manual documentation." in
  let man_xrefs = [ `Main ] in
  let man = [
    `S Manpage.s_synopsis;
    `P "$(mname) $(tname) $(i,ACTION) [$(i,OPTION)]...";
    `S Manpage.s_description;
    `P "$(tname) lists and sets the theme used by odoc documentation.";
    `P "See the packaging conventions in $(b,odig doc) $(mname) for the \
        theme install structure.";
    `S "ACTIONS";
    `I ("$(b,list)", "List available themes.");
    `I ("$(b,default)", "Show the default theme name. This is either,
        in order, the value of the  $(b,--odoc-theme) option,
        or the value of the $(b,ODIG_ODOC_THEME) environment variable, or the
        stripped contents of the $(b,~/.config/odig/odoc-theme) file
        or $(b,odoc.default).");
    `I ("$(b,set) [$(b,--default)] [$(b,THEME)]",
        "Use the theme $(b,THEME). If $(b,THEME) is unspecified the
         default theme is used. If $(b,--default) is specified the
         used theme name is persisted to the file
         $(b,~/.config/odig/odoc-theme).");
    `I ("$(b,path) [$(b,THEME)]", "Show path to theme $(b,THEME). If
         $(b,THEME) is unspecfied the default theme is used."); ]
  in
  let action =
    let action =
      [ "list", `List; "default", `Default; "set", `Set; "path", `Path;]
    in
    let doc = Fmt.str "The action to perform. $(docv) must be one of %s."
        (Arg.doc_alts_enum action)
    in
    let action = Arg.enum action in
    Arg.(required & pos 0 (some action) None & info [] ~doc ~docv:"ACTION")
  in
  let theme =
    let doc = "Theme name." in
    Arg.(value & pos 1 (some string) None & info [] ~doc ~docv:"THEME")
  in
  let set_default =
    let doc =
      "On $(b,set), write the theme name to $(b,~/.config/odig/odoc-theme)."
    in
    Arg.(value & flag & info ["default"] ~doc)
  in
  Term.(const odoc_theme_cmd $ conf $ details $ action $ theme $ set_default),
  Term.info "odoc-theme" ~doc ~sdocs ~exits ~man ~man_xrefs

let log_cmd =
  let doc = "Show odoc build log" and man_xrefs = [ `Main ] in
  let docs_format = "OUTPUT FORMAT" in
  let docs_details = "OUTPUT DETAILS" in
  let docs_selection = "OPTIONS FOR SELECTING OPERATIONS" in
  let envs = B0_pager.envs () in
  let man = [
    `S Manpage.s_description;
    `P "The $(tname) command shows odoc build operations.";
    `Blocks B00_ui.Op.query_man;
    `S docs_format;
    `S docs_details;
    `S docs_selection; ]
  in
  Term.(const log_cmd $ conf $ no_pager $
        B00_ui.Memo.Log.out_format_cli ~docs:docs_format () $
        B00_ui.Cli.out_details ~docs:docs_details () $
        B00_ui.Op.query_cli ~docs:docs_selection ()),
  Term.info "log" ~doc ~sdocs ~exits ~envs ~man ~man_xrefs

let pkg_cmd =
  let doc = "Show packages (default command)" in
  let man_xrefs = [ `Main ] in
  let envs = B0_pager.envs () in
  let man = [
    `S Manpage.s_description;
    `P "The $(tname) command shows packages known to odig. If no packages
        are specified, all packages are shown.";
    `P "See the packaging conventions in $(b,odig doc) $(mname) for the package
        install structure.";]
  in
  Term.(const pkg_cmd $ conf $ no_pager $ details $ pkgs_pos),
  Term.info "pkg" ~doc ~sdocs ~envs ~exits ~man ~man_xrefs

let readme_cmd = show_files_cmd ~kind:"readme" Doc_dir.readme_files
let show_cmd =
  let doc = "Show package metadata" and man_xrefs = [ `Main ] in
  let envs = B0_pager.envs () in
  let man = [
    `S Manpage.s_description;
    `P "$(tname) outputs package metadata. If no packages
        are specified, information for all packages is shown.";
    `P "Outputs a single non-empty value per line; to output empty
        value use the $(b,--show-empty) option.";
    `P "To preceed values by the name of the package they apply to, use
        the $(b,--long) option."; ]
  in
  let field =
    let field = Odig_support.Pkg_info.field_names in
    let alts = Arg.doc_alts_enum field in
    let doc = Fmt.str "The field to show. $(docv) must be %s." alts in
    let action = Arg.enum field in
    Arg.(required & pos 0 (some action) None & info [] ~doc ~docv:"FIELD")
  in
  let show_empty =
    let doc = "Show empty fields." in
    Arg.(value & flag & info ["e"; "show-empty"] ~doc)
  in
  Term.(const show_cmd $ conf $ no_pager $ details $ show_empty $ field $
        pkgs_pos1),
  Term.info "show" ~doc ~sdocs ~envs ~exits ~man ~man_xrefs

(* Main command *)

let odig =
  let doc = "Lookup documentation of installed OCaml packages" in
  let man = [
    `S Manpage.s_description;
    `P "$(mname) looks up documentation of installed OCaml packages. It shows \
        package metadata, readmes, change logs, licenses, cross-referenced \
        $(b,odoc) API documentation and manuals.";
    `P "See $(b,odig doc) $(mname) for a tutorial and more details."; `Noblank;
    `P "See $(mname) $(b,conf --help) for information about $(mname) \
        configuration.";
    `S Manpage.s_see_also;
    `P "Consult $(b,odig doc odig) for a tutorial, packaging conventions and
         more details.";
    `S Manpage.s_bugs;
    `P "Report them, see $(i,%%PKG_HOMEPAGE%%) for contact information." ];
  in
  fst pkg_cmd,
  Term.info "odig" ~version:"%%VERSION%%" ~doc ~sdocs ~exits ~man

let () =
  let cmds =
    [ browse_cmd; cache_cmd; changes_cmd; conf_cmd; doc_cmd; license_cmd;
      log_cmd; odoc_cmd; odoc_theme_cmd; pkg_cmd; readme_cmd; show_cmd; ]
  in
  Term.exit_status @@
  Log.time (fun _ m -> m "total time") @@ fun () -> Term.eval_choice odig cmds

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
