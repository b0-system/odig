(*---------------------------------------------------------------------------
   Copyright 2013 Daniel C. Bünzli. All rights reserved.
   Distributed under the BSD3 license, see license at the end of the file.
   %%NAME%% release %%VERSION%%
  ---------------------------------------------------------------------------*)

(* Raw dump of the data read by glreg.mli *) 

let str = Printf.sprintf
let exec = Filename.basename Sys.executable_name

let pp = Format.fprintf 
let rec pp_list ?(pp_sep = Format.pp_print_cut) pp_v ppf = function 
| [] -> ()
| v :: vs -> 
    pp_v ppf v; if vs <> [] then (pp_sep ppf (); pp_list ~pp_sep pp_v ppf vs)

let pp_kv k ppf = function 
| None -> () | Some v -> pp ppf "@ %s:'%s'" k v

let pp_type ppf _ ts = 
  let pp_type_def ppf t = 
    Glreg.(pp ppf "@[<2>type '%s' = '%s'%a%a@]@," 
             t.t_name t.t_def 
             (pp_kv "api") t.t_api 
             (pp_kv "requires") t.t_requires)
  in
  List.iter (pp_type_def ppf) (List.rev ts)

let pp_group ppf _ g =
  let pp_sep ppf () = pp ppf "@ | " in
  let pp_enum ppf e = pp ppf "'%s'" e in
  Glreg.(pp ppf "@[<2>group '%s' =@ %a@]@," 
           g.g_name (pp_list ~pp_sep pp_enum) g.g_enums)

let pp_enum ppf _ es =
  let pp_enum_def ppf e =
      Glreg.(pp ppf "@[<2>enum '%s' = '%s'@ ns:%s%a%a%a%a%a@]@,"
               e.e_name e.e_value e.e_p_namespace 
               (pp_kv "ptype") e.e_p_type
               (pp_kv "vendor") e.e_p_vendor
               (pp_kv "api") e.e_api
               (pp_kv "type") e.e_type
               (pp_kv "alias") e.e_alias)
  in
  List.iter (pp_enum_def ppf) (List.rev es)

let pp_param_type ppf p = 
  let pp_group ppf = function None -> () | Some g -> pp ppf "[%s] " g in 
  let pp_len ppf = function None -> () | Some l -> pp ppf " (len: '%s')" l in
  Glreg.(pp ppf "%a'%s'%a" pp_group p.p_group p.p_type pp_len p.p_len)
    
let pp_command ppf _ cs = 
  let pp_param ppf (p, t) = pp ppf "param %s : %a" p pp_param_type t in
  let pp_cmd_def ppf c = 
    Glreg.(pp ppf "@[<2>cmd '%s' ns:%s%a%a@\n@[<v>ret: %a@,%a@]@]@," 
             c.c_name c.c_p_namespace 
             (pp_kv "alias") c.c_alias 
             (pp_kv "vec") c.c_vec_equiv 
             pp_param_type c.c_ret
             (pp_list pp_param) c.c_params)
  in
  List.iter (pp_cmd_def ppf) (List.rev cs)

let pp_i_element pre ppf i = 
  let tstr = function `Command -> "cmd" | `Type -> "type" | `Enum -> "enum" in
  Glreg.(pp ppf "@[%s %s '%s'%a%a@]"
           pre (tstr i.i_type) i.i_name 
           (pp_kv "api") i.i_api 
           (pp_kv "profile") i.i_profile)
    
let pp_feature ppf _ fs = 
  let pp_feat_def ppf f = 
    Glreg.(pp ppf 
             "@[<2>feature api:'%s' number:%d.%d@\n@[<v>%a%a@]@]@,"
             f.f_api (fst f.f_number) (snd f.f_number)
             (pp_list (pp_i_element "req")) (List.rev f.f_require)
             (pp_list (pp_i_element "rem")) (List.rev f.f_remove))
  in
  List.iter (pp_feat_def ppf) (List.rev fs)

let pp_extension ppf _ x = 
  Glreg.(pp ppf "@[<2>ext '%s'%a@\n@[<v>%a%a@]@]@,"
           x.x_name (pp_kv "supported") x.x_supported
           (pp_list (pp_i_element "req")) (List.rev x.x_require)
           (pp_list (pp_i_element "rem")) (List.rev x.x_remove))

let pp_registry ppf r =
  pp ppf "@[<v>";
  Hashtbl.iter (pp_type ppf) r.Glreg.types; pp ppf "@,";
  Hashtbl.iter (pp_group ppf) r.Glreg.groups; pp ppf "@,";
  Hashtbl.iter (pp_enum ppf) r.Glreg.enums; pp ppf "@,";
  Hashtbl.iter (pp_command ppf) r.Glreg.commands; pp ppf "@,";
  Hashtbl.iter (pp_feature ppf) r.Glreg.features; pp ppf "@,";
  Hashtbl.iter (pp_extension ppf) r.Glreg.extensions; pp ppf "@,";
  pp ppf "@]@?"
    
let dump inf = 
  try
    let inf = match inf with None -> "-" | Some inf -> inf in
    let ic = if inf = "-" then stdin else open_in inf in
    let d = Glreg.decoder (`Channel ic) in
    try match Glreg.decode d with
    | `Ok r -> close_in ic; pp_registry Format.std_formatter r
    | `Error e -> 
        let (l0, c0), (l1, c1) = Glreg.decoded_range d in
        Printf.eprintf "%s:%d.%d-%d.%d: %s\n%!" inf l0 c0 l1 c1 e; 
        exit 1
    with e -> close_in ic; raise e
  with Sys_error e -> Printf.eprintf "%s\n%!" e; exit 1
        
let main () =
  let usage = 
    str "Usage: %s FILE\n\
         Dumps an OpenGL XML registry file on stdout.\n\
         Options:" exec
  in
  let inf = ref None in 
  let set_inf f =
    if !inf = None then inf := Some f else
    raise (Arg.Bad "only one registry file can be specified")
  in
  let options = [] in
  Arg.parse (Arg.align options) set_inf usage; 
  dump !inf
    
let () = main ()

(*---------------------------------------------------------------------------
   Copyright 2013 Daniel C. Bünzli.
   All rights reserved.

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions
   are met:
     
   1. Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.

   2. Redistributions in binary form must reproduce the above
      copyright notice, this list of conditions and the following
      disclaimer in the documentation and/or other materials provided
      with the distribution.

   3. Neither the name of Daniel C. Bünzli nor the names of
      contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
   "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
   A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
   OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
   LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
   DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
   THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
   (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
   OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
  ---------------------------------------------------------------------------*)
