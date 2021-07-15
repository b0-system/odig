(* This code is in the public domain *)

let otf_postscript_name bytes =
  let d = Otfm.decoder (`String bytes) in
  match Otfm.postscript_name d with
  | Error e -> Format.eprintf "@[%a@]@." Otfm.pp_error e
  | Ok (Some n) -> Format.printf "%s@." n;
  | Ok None -> ()
