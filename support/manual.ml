(*---------------------------------------------------------------------------
   Copyright (c) 2013 Daniel C. Bünzli. All rights reserved.
   Distributed under the BSD3 license, see license at the end of the file.
   %%NAME%% release %%VERSION%%
  ---------------------------------------------------------------------------*)

let pp = Format.fprintf 
let str = Printf.sprintf
type binding = string * string

let get_uri api f = match Doc.man_uri api f with 
| Some doc -> doc | None -> assert false 

let glCreateShaderProgramv api = str 
"\
val create_shader_programv : enum -> string -> int
(** {{:%s}
    [glCreateShaderProgramv]} [type_ source] *)
" 
(get_uri api "glCreateShaderProgramv"),
"\
let create_shader_programv =
  foreign ~stub \"glCreateShaderProgramv\"
    (int_as_uint @-> int @-> ptr string @-> returning int_as_uint)

let create_shader_programv type_ src =
  let src = allocate string src in
  create_shader_programv type_ 1 src
"

let glDebugMessageCallback api = str 
"\
val debug_message_callback : debug_proc -> unit
(** {{:%s}
    [glDebugMessageCallback]} [f] *)
"
(get_uri api "glDebugMessageCallback"),
"\

let debug_message_callback =
  foreign ~stub \"glDebugMessageCallback\"
    ((funptr (int_as_uint @-> int_as_uint @-> int_as_uint @->
              int_as_uint @-> int @-> ptr char @-> ptr void @->
              returning void)) @->
     ptr void @-> returning void)

let debug_message_callback f =
  let wrap_cb src typ id sev len msg _ =
    let s = String.create len in
    for i = 0 to len - 1 do s.[i] <- !@ (msg +@ i) done;
    f src typ id sev s
  in
  debug_message_callback wrap_cb null
"

let glGetUniformIndices api = str
"\
val get_uniform_indices : int -> string list -> uint32_bigarray -> unit
(** {{:%s}
    [glGetUniformIndices]} [program uniformNames uniformIndices] *)"
(get_uri api "glGetUniformIndices"),
"\
let get_uniform_indices =
  foreign ~stub \"glGetUniformIndices\"
    (int_as_uint @-> int @-> ptr string @-> ptr void @-> returning void)

let get_uniform_indices program names indices =
  let count = List.length names in
  let names = Array.(start (of_list string names)) in
  let indices = to_voidp (bigarray_start array1 indices) in
  get_uniform_indices program count names indices
"

let glMapBuffer api = str
"\
val map_buffer : enum -> int -> enum -> ('a, 'b) Bigarray.kind ->
  ('a, 'b) bigarray
(** {{:%s}
    [glMapBuffer]} [target length access kind]

    {b Note.} [length] is the length, in number of bigarray elements, of the
    mapped buffer.

    {b Warning.} The bigarray becomes invalid once the buffer is unmapped and 
    program termination may happen if you don't respect the access policy. *)
"
(get_uri api "glMapBuffer"),
"\
let map_buffer =
  foreign ~stub \"glMapBuffer\"
    (int_as_uint @-> int_as_uint @-> returning (ptr void))

let map_buffer target len access kind =
  let p = map_buffer target access in
  let p = coerce (ptr void) (access_ptr_typ_of_ba_kind kind) p in
  bigarray_of_ptr array1 len kind p
"

let glMapBufferRange api = str
"\
val map_buffer_range : enum -> int -> int -> enum -> 
  ('a, 'b) Bigarray.kind -> ('a, 'b) bigarray
(** {{:%s}
    [glMapBufferRanage]} [target offset length access kind]

    {b Note.} [length] is the length in number of bigarray elements of the
    mapped buffer. [offset] is in bytes.

    {b Warning.} The bigarray becomes invalid once the buffer is unmapped and 
    program termination may happen if you don't respect the access policy. *)
"
(get_uri api "glMapBufferRange"),
"\
let map_buffer_range =
  foreign ~stub \"glMapBufferRange\"
    (int_as_uint @-> int @-> int @-> int_as_uint @-> returning (ptr void))

let map_buffer_range target offset len access kind =
  let len_bytes = ba_kind_byte_size kind * len in
  let p = map_buffer_range target offset len_bytes access in
  let p = coerce (ptr void) (access_ptr_typ_of_ba_kind kind) p in
  bigarray_of_ptr array1 len kind p
"

let glShaderSource api = str 
"\
val shader_source : int -> string -> unit
(** {{:%s}
    [glShaderSource]} [shader source] *)
"
(get_uri api "glShaderSource"),
"\
let shader_source =
  foreign ~stub \"glShaderSource\"
    (int_as_uint @-> int @-> ptr string @-> ptr void @-> returning void)

let shader_source sh src =
  let src = allocate string src in
  shader_source sh 1 src null
"

let glTransformFeedbackVaryings api = str
"\
val transform_feedback_varyings : int -> string list -> enum -> unit
(** {{:%s}
    [glTransformFeedbackVaryings]} [program varyings bufferMode] *)"
(get_uri api "glTransformFeedbackVaryings"),
"\
let transform_feedback_varyings =
  foreign ~stub \"glTransformFeedbackVaryings\"
    (int_as_uint @-> int @-> ptr string @-> int_as_uint @-> returning void)

let transform_feedback_varyings program varyings mode =
  let count = List.length varyings in
  let varyings = Array.(start (of_list string varyings)) in
  transform_feedback_varyings program count varyings mode
"

let get api = function
| "glCreateShaderProgramv" -> Some (glCreateShaderProgramv api)
| "glDebugMessageCallback" -> Some (glDebugMessageCallback api)
| "glGetUniformIndices" -> Some (glGetUniformIndices api)
| "glMapBuffer" -> Some (glMapBuffer api)
| "glMapBufferRange" -> Some (glMapBufferRange api)
| "glShaderSource" -> Some (glShaderSource api)
| "glTransformFeedbackVaryings" -> Some (glTransformFeedbackVaryings api)
| _ -> None

(*---------------------------------------------------------------------------
   Copyright (c) 2013 Daniel C. Bünzli.
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
