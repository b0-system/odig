(* This code is in the public domain *)

let utf_8_normalize nf s =
  let b = Buffer.create (String.length s * 3) in
  let n = Uunf.create nf in
  let rec add v = match Uunf.add n v with
  | `Uchar u -> Uutf.Buffer.add_utf_8 b u; add `Await
  | `Await | `End -> ()
  in
  let add_uchar _ _ = function
  | `Malformed _ -> add (`Uchar Uutf.u_rep)
  | `Uchar _ as u -> add u
  in
  Uutf.String.fold_utf_8 add_uchar () s; add `End; Buffer.contents b
