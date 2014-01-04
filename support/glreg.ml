(*---------------------------------------------------------------------------
   Copyright 2013 Daniel C. Bünzli. All rights reserved.
   Distributed under the BSD3 license, see license at the end of the file.
   %%NAME%% release %%VERSION%%
  ---------------------------------------------------------------------------*)

let str = Printf.sprintf
let str_of_name (u,l) = str "{%s}%s" u l 
let split_string s sep =
  let rec split accum j = 
    let i = try (String.rindex_from s j sep) with Not_found -> -1 in
    if (i = -1) then 
      let p = String.sub s 0 (j + 1) in 
      if p <> "" then p :: accum else accum
    else 
    let p = String.sub s (i + 1) (j - i) in
    let accum' = if p <> "" then p :: accum else accum in
    split accum' (i - 1)
  in
  split [] (String.length s - 1)

(* Error messages *)

let err s = failwith s
let err_group_def n = str "group %s already defined" n
let err_enum_def n = str "enum %s already defined" n
let err_ext_def n = str "extension %s already defined" n
let err_vnum n = str "cannot parse X.Y version number (%s)" n
let err_data = "character data not allowed here"
let err_exp_el_end = "expected end of element"
let err_exp_data = "expected character data"
let err_wf = "document not well formed"
let err_miss_att n = str "missing attribute (%s)" (str_of_name n)
let err_miss_el n = str "missing element (%s)" (str_of_name n)
let err_exp_registry f = 
  str "expected registry element found %s" (str_of_name f)

(* Registry representation *)

type typ = 
  { t_name : string;
    t_api : string option; 
    t_requires : string option; 
    t_def : string; }

type group = 
  { g_name : string; 
    g_enums : string list; }

type enum = 
  { e_name : string; 
    e_p_namespace : string; 
    e_p_type : string option; 
    e_p_group : string option;
    e_p_vendor : string option;
    e_value : string;
    e_api : string option; 
    e_type : string option;
    e_alias : string option; }

type param_type = 
  { p_group : string option; 
    p_type : string; 
    p_len : string option;
    p_nullable : bool; }

type command = 
  { c_name : string; 
    c_p_namespace : string;
    c_ret : param_type; 
    c_params : (string * param_type) list;
    c_alias : string option; 
    c_vec_equiv : string option; }

type i_element = 
  { i_name : string;
    i_type : [ `Enum | `Command | `Type ]; 
    i_api : string option;
    i_profile : string option; }

type feature = 
  { f_api : string; 
    f_number : int * int;
    f_require : i_element list; 
    f_remove : i_element list; }

type extension = 
  { x_name : string; 
    x_supported : string option; 
    x_require : i_element list; 
    x_remove : i_element list; }

type t =
  { types : (string, typ list) Hashtbl.t; 
    groups : (string, group) Hashtbl.t; 
    enums : (string, enum list) Hashtbl.t;
    commands : (string, command list) Hashtbl.t; 
    features : (string, feature list) Hashtbl.t;
    extensions : (string, extension) Hashtbl.t; }

let add err_def ht n v = 
  try ignore (Hashtbl.find ht n); err (err_def n) with 
  | Not_found -> Hashtbl.add ht n v

let add_list ht n v =   
  try Hashtbl.replace ht n (v :: (Hashtbl.find ht n)) 
  with Not_found -> Hashtbl.add ht n [v]

let add_type r n t = add_list r.types n t                       
let add_group r n g = add err_group_def r.groups n g
let add_enum r n e = add_list r.enums n e
let add_command r n c = add_list r.commands n c
let add_feature r n f = add_list r.features n f 
let add_extension r n x = add err_ext_def r.extensions n x

(* Decode *) 

(* XML names *) 

let ns_gl = ""
let n_alias = (ns_gl, "alias")
let n_api = (ns_gl, "api")
let n_commands = (ns_gl, "commands")
let n_command = (ns_gl, "command")
let n_comment = (ns_gl, "comment")
let n_enum = (ns_gl, "enum")
let n_enums = (ns_gl, "enums")
let n_extensions = (ns_gl, "extensions")
let n_extension = (ns_gl, "extension")
let n_feature = (ns_gl, "feature")
let n_group = (ns_gl, "group")
let n_groups = (ns_gl, "groups")
let n_len = (ns_gl, "len")
let n_name = (ns_gl, "name")
let n_namespace = (ns_gl, "namespace")
let n_number = (ns_gl, "number")
let n_param = (ns_gl, "param")
let n_proto = (ns_gl, "proto")
let n_profile = (ns_gl, "profile")
let n_ptype = (ns_gl, "ptype")
let n_registry = (ns_gl, "registry")
let n_requires = (ns_gl, "requires")
let n_require = (ns_gl, "require")
let n_remove = (ns_gl, "remove")
let n_supported = (ns_gl, "supported")
let n_type = (ns_gl, "type")
let n_types = (ns_gl, "types") 
let n_value = (ns_gl, "value")
let n_vecequiv = (ns_gl, "vecequiv")
let n_vendor = (ns_gl, "vendor")

let attv n atts =               (* value of attribute [n] in atts or raises. *)
  try snd (List.find (fun (en, v) -> en = n) atts) with
  | Not_found -> err (err_miss_att n)

let attv_opt n atts =             (* value of attribute [n] in atts, if any. *)
  try Some (snd (List.find (fun (en, v) -> en = n) atts)) with
  | Not_found -> None

let rec skip_el d =             (* skips an element, start signal was input. *)
  let rec loop d depth = match Xmlm.input d with
  | `El_start _ -> loop d (depth + 1)
  | `El_end -> if depth = 0 then () else loop d (depth - 1)
  | s -> loop d depth
  in
  loop d 0 

let p_data d = match Xmlm.input d with   (* gets data and parses end signal. *)
| `Data data -> 
    begin match Xmlm.input d with 
    | `El_end -> data
    | _ -> err err_exp_el_end
    end
| _ -> err err_exp_data

let p_seq r d n p_el = 
  let rec loop r d = match Xmlm.input d with 
  | `El_end -> () 
  | `El_start (n, atts) when n = n -> p_el r d atts; loop r d
  | `El_start _ -> skip_el d; loop r d
  | `Data _ -> err err_data 
  | _ -> assert false
  in
  loop r d

let p_type r d atts = 
  let t_name = ref (attv_opt n_name atts) in 
  let t_requires = attv_opt n_requires atts in 
  let t_api = attv_opt n_api atts in
  let def = Buffer.create 255 in
  let rec loop r d = match Xmlm.input d with 
  | `El_start (n, _) when n = n_name -> t_name := Some (p_data d); loop r d
  | `El_start (n, _) -> skip_el d; loop r d
  | `El_end -> 
      let t_name = match !t_name with None -> "" | Some name -> name in
      let t_def = 
        let d = Buffer.contents def in
        let d = if String.length d <= 8 then d else match String.sub d 0 8 with
        | "typedef " -> String.sub d 8 (String.length d - 8 - 1) | _ -> d
        in
        try String.sub d 0 (String.rindex d ';') with Not_found -> d
      in
      add_type r t_name { t_name; t_api; t_requires; t_def; }
  | `Data s -> Buffer.add_string def s; loop r d
  | _ -> assert false
  in
  loop r d 

let p_group r d atts = 
  let g_name = attv n_name atts in 
  let rec loop acc r d = match Xmlm.input d with 
  | `El_start (n, atts) when n = n_enum -> 
      begin match Xmlm.input d with 
      | `El_end -> loop ((attv n_name atts) :: acc) r d 
      | _ -> err err_exp_el_end
      end
  | `El_start _ -> skip_el d; loop acc r d
  | `El_end ->
      add_group r g_name { g_name; g_enums = (List.rev acc); }
  | `Data _ -> err err_data 
  | _ -> assert false
  in
  loop [] r d 

let p_enums r d atts = 
  let e_p_namespace = attv n_namespace atts in 
  let e_p_type = attv_opt n_type atts in
  let e_p_group = attv_opt n_group atts in
  let e_p_vendor = attv_opt n_type atts in
  let rec loop r d = match Xmlm.input d with 
  | `El_start (n, atts) when n = n_enum -> 
      begin match Xmlm.input d with 
      | `El_end -> 
          let e_name = attv n_name atts in 
          let e_value = attv n_value atts in 
          let e_api = attv_opt n_api atts in 
          let e_type = attv_opt n_type atts in 
          let e_alias = attv_opt n_alias atts in 
          let e = { e_name; e_p_namespace; e_p_group; e_p_type; e_p_vendor;
                    e_value; e_api; e_type; e_alias; }
          in
          add_enum r e_name e; 
          loop r d
      | _ -> err err_exp_el_end
      end
  | `El_start _ -> skip_el d; loop r d 
  | `El_end -> ()
  | `Data _ -> err err_data 
  | _ -> assert false
  in
  loop r d

let p_param r d atts =
  let p_group = attv_opt n_group atts in
  let p_len = attv_opt n_len atts in
  let p_type = Buffer.create 255 in
  let name = ref None in
  let rec loop r d = match Xmlm.input d with 
  | `El_start (n, _) when n = n_name -> name := Some (p_data d); loop r d
  | `El_start (n, _) when n = n_ptype ->
      if Buffer.length p_type <> 0 then Buffer.add_char p_type ' ';
      Buffer.add_string p_type (p_data d); loop r d
  | `El_end -> 
      let name = match !name with 
      | None -> err (err_miss_el n_name) 
      | Some name -> name 
      in
      let p_type = Buffer.contents p_type in
      name, { p_group; p_type; p_len; p_nullable = false; }
  | `Data s -> 
      if Buffer.length p_type <> 0 && s <> "" then Buffer.add_char p_type ' ';
      Buffer.add_string p_type s; loop r d
  | _ -> assert false
  in
  loop r d 
  
let p_command c_p_namespace r d atts =
  let c_proto = ref None in
  let c_params = ref [] in 
  let c_alias = ref None in 
  let c_vec_equiv = ref None in
  let rec loop r d = match Xmlm.input d with 
  | `El_start (n, atts) when n = n_proto -> 
      c_proto := Some (p_param r d atts); loop r d 
  | `El_start (n, atts) when n = n_param -> 
      c_params := (p_param r d atts) :: !c_params; loop r d
  | `El_start (n, atts) when n = n_alias -> 
      c_alias := Some (attv n_name atts); skip_el d; loop r d
  | `El_start (n, atts) when n = n_vecequiv -> 
      c_vec_equiv := Some (attv n_name atts); skip_el d; loop r d
  | `El_start _ -> 
      skip_el d; loop r d 
  | `El_end -> 
      let c_name, c_ret = match !c_proto with 
      | None -> err (err_miss_el n_proto) | Some v -> v 
      in 
      (* add info not present in the registry. *) 
      let add_miss_arg f (arg, p) = 
        let p = 
          if not (Fixreg.is_arg_nullable f arg) then p else
          { p with p_nullable = true } 
        in
        let p = 
          if not (Fixreg.is_arg_voidp_or_index f arg) then p else
          let l = String.index p.p_type 'd' in (* void -> void_or_index *)
          { p with p_type = (String.sub p.p_type 0 (l + 1)) ^ "_or_index" ^
                            (String.sub p.p_type (l + 1) 
                               (String.length p.p_type - l - 1)) }
        in
        (arg, p)
      in
      let add_miss_ret f p = 
        if Fixreg.is_ret_nullable f then {p with p_nullable = true} else p 
      in
      add_command r c_name 
        { c_name; c_p_namespace; 
          c_ret = add_miss_ret c_name c_ret;
          c_params = List.rev_map (add_miss_arg c_name) (!c_params);
          c_alias = !c_alias; c_vec_equiv = !c_vec_equiv; }
  | `Data _ -> err err_data 
  | _ -> assert false 
  in
  loop r d

let p_version s = 
  let l = String.length s in
  try
    let d = String.rindex s '.' in 
    int_of_string (String.sub s 0 d), 
    int_of_string (String.sub s (d + 1) (l - d - 1))
  with _ -> err (err_vnum s)

let p_i_elements d atts acc = 
  let i_api = attv_opt n_api atts in
  let i_profile = attv_opt n_profile atts in 
  let p_element d i_type atts = 
    let i_name = attv n_name atts in 
    begin match Xmlm.input d with 
    | `El_end -> { i_type; i_name; i_api; i_profile } 
    | _ -> err (err_exp_el_end)
    end
  in
  let rec loop acc d = match Xmlm.input d with 
  | `El_start (n, atts) when n = n_enum -> 
      loop ((p_element d `Enum atts) :: acc) d
  | `El_start (n, atts) when n = n_command -> 
      loop ((p_element d `Command atts) :: acc) d 
  | `El_start (n, atts) when n = n_type -> 
      loop ((p_element d `Type atts) :: acc) d 
  | `El_start _ -> skip_el d; loop acc d 
  | `El_end -> acc
  | _ -> assert false
  in
  loop acc d

let p_feature r d atts =
  let f_api = attv n_api atts in 
  let f_number = p_version (attv n_number atts) in
  let f_require = ref [] in 
  let f_remove = ref [] in
  let rec loop r d = match Xmlm.input d with 
  | `El_start (n, atts) when n = n_require -> 
      f_require := p_i_elements d ((n_api, f_api) :: atts) !f_require; loop r d
  | `El_start (n, atts) when n = n_remove -> 
      f_remove := p_i_elements d ((n_api, f_api) :: atts) !f_remove; loop r d
  | `El_start _ -> skip_el d 
  | `El_end -> 
      add_feature r f_api 
        { f_api; f_number; f_require = !f_require; f_remove = !f_remove }
  | `Data _ -> err err_data 
  | _ -> assert false 
  in
  loop r d 

let p_extension r d atts =
  let x_name = attv n_name atts in 
  let x_supported = attv_opt n_supported atts in 
  let x_require = ref [] in 
  let x_remove = ref [] in 
  let rec loop r d = match Xmlm.input d with 
  | `El_start (n, atts) when n = n_require -> 
      x_require := p_i_elements d atts !x_require; loop r d
  | `El_start (n, atts) when n = n_remove -> 
      x_remove := p_i_elements d atts !x_remove; loop r d
  | `El_start _ -> skip_el d 
  | `El_end -> 
      add_extension r x_name
        { x_name; x_supported; x_require = !x_require; x_remove = !x_remove }
  | `Data _ -> err err_data 
  | _ -> assert false 
  in
  loop r d 

let p_registry d =
  let r = 
    { types = Hashtbl.create 503;
      groups = Hashtbl.create 503; 
      enums = Hashtbl.create 6047; 
      commands = Hashtbl.create 10047;
      features = Hashtbl.create 97; 
      extensions = Hashtbl.create 1003; }
  in
  while (Xmlm.peek d <> `El_end) do match Xmlm.input d with 
  | `El_start (n, _) when n = n_types -> p_seq r d n_type p_type
  | `El_start (n, _) when n = n_groups -> p_seq r d n_group p_group
  | `El_start (n, atts) when n = n_enums -> p_enums r d atts
  | `El_start (n, atts) when n = n_commands -> 
      let ns = attv n_namespace atts in
      p_seq r d n_command (p_command ns)
  | `El_start (n, atts) when n = n_feature -> p_feature r d atts 
  | `El_start (n, atts) when n = n_extensions -> 
      p_seq r d n_extension p_extension
  | `El_start (n, _) -> skip_el d 
  | `Data _ -> err err_data 
  | _ -> assert false; 
  done;
  ignore (Xmlm.input d); 
  if not (Xmlm.eoi d) then err err_wf; 
  r
      
type src = [ `Channel of in_channel | `String of string ]
type decoder = Xmlm.input

let decoder src =
  let src = match src with `String s -> `String (0, s) | `Channel _ as s -> s in
  Xmlm.make_input ~strip:true src

let decoded_range d = Xmlm.pos d, Xmlm.pos d
let decode d = try
  ignore (Xmlm.input d); (* `Dtd *)
  begin match Xmlm.input d with
  | `El_start (n, _) when n = n_registry -> `Ok (p_registry d) 	
  | `El_start (n, _) -> err (err_exp_registry n)
  | _ -> assert false
  end;
with
| Failure e -> `Error e | Xmlm.Error (_, e) -> `Error (Xmlm.error_message e)

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
