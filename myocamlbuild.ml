open Ocamlbuild_plugin

let strf = Printf.sprintf

(* Handle byte/native specific Odig_ocamltop module implementation. *)

let cp = if Sys.win32 then "copy" else "cp"

let cp_odig_ocamltop dir ext =
  let cmi = "%odig_ocamltop.cmi" in (* make sure it is built and seen *)
  let src = strf "%%%s/odig_ocamltop.%s" dir ext in
  let dst = strf "%%odig_ocamltop.%s" ext in
  rule (strf "cp %s to %s" src dst)
    ~prod:dst
    ~deps:[cmi; src]
    ~insert:`top
    begin fun env _build ->
      Cmd (S [ A cp; A (env src); A (env dst)])
    end

let () =
  dispatch begin function
  | After_rules ->
      cp_odig_ocamltop "byte" "cmo";
      cp_odig_ocamltop "native" "cmx";
      cp_odig_ocamltop "native" "o";

      (* When compiled with TOPKG_CONF_DEBUGGER_SUPPORT, topkg will
         ask for odig_ocamltop.ml because of odig.mllib. We provide
         the native-code one. The `bottom insertion and `top insertion
         of previous rules ensure this file doesn't get used to
         implement the cmo. *)
      copy_rule ~insert:`bottom "copy odig_ocamltop.ml source"
        "src/native/odig_ocamltop.ml" "src/odig_ocamltop.ml";
  | _ -> ()
  end
