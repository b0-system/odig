(*
   Minimal Tgles3 example. This code is in the public domain.
   Draws a fantastic tri-colored triangle.

   Compile with:
   ocamlfind ocamlc -linkpkg -package result,tsdl,tgls.tgles3 -o trigles3.byte \
                    trigles3.ml
   ocamlfind ocamlopt -linkpkg -package result,tsdl,tgls.tgles3 -o trigles3.native \
                      trigles3.ml
*)

open Tsdl
open Tgles3
open Result

let str = Printf.sprintf

let ( >>= ) x f = match x with Ok v -> f v | Error _ as e -> e

(* Helper functions. *)

let bigarray_create k len = Bigarray.(Array1.create k c_layout len)

let get_int =
  let a = bigarray_create Bigarray.int32 1 in
  fun f -> f a; Int32.to_int a.{0}

let set_int =
  let a = bigarray_create Bigarray.int32 1 in
  fun f i -> a.{0} <- Int32.of_int i; f a

let get_string len f =
  let a = bigarray_create Bigarray.char len in
  f a; Gl.string_of_bigarray a

(* Shaders *)

let vertex_shader = "
  #version 330 es
  in vec3 vertex;
  in vec3 color;
  out vec4 v_color;
  void main()
  {
    v_color = vec4(color, 1.0);
    gl_Position = vec4(vertex, 1.0);
  }"

let fragment_shader = "
  #version 330 es
  precision highp float;
  in vec4 v_color;
  out vec4 color;
  void main() { color = v_color; }"

(* Geometry *)

let set_3d ba i x y z =
  let start = i * 3 in
  ba.{start} <- x; ba.{start + 1} <- y; ba.{start + 2} <- z

let vertices =
  let vs = bigarray_create Bigarray.float32 (3 * 3) in
  set_3d vs 0 (-0.8) (-0.8) 0.0;
  set_3d vs 1 0.8    (-0.8) 0.0;
  set_3d vs 2 0.0    0.8    0.0;
  vs

let colors =
  let cs = bigarray_create Bigarray.float32 (3 * 3) in
  set_3d cs 0 1.0 0.0 0.0;
  set_3d cs 1 0.0 1.0 0.0;
  set_3d cs 2 0.0 0.0 1.0;
  cs

let indices =
  let is = bigarray_create Bigarray.int8_unsigned 3 in
  set_3d is 0 0 1 2;
  is

(* OpenGL setup *)

let create_buffer b =
  let id = get_int (Gl.gen_buffers 1) in
  let bytes = Gl.bigarray_byte_size b in
  Gl.bind_buffer Gl.array_buffer id;
  Gl.buffer_data Gl.array_buffer bytes (Some b) Gl.static_draw;
  id

let delete_buffer bid =
  set_int (Gl.delete_buffers 1) bid

let create_geometry () =
  let gid = get_int (Gl.gen_vertex_arrays 1) in
  let iid = create_buffer indices in
  let vid = create_buffer vertices in
  let cid = create_buffer colors in
  let bind_attrib id loc dim typ =
    Gl.bind_buffer Gl.array_buffer id;
    Gl.enable_vertex_attrib_array loc;
    Gl.vertex_attrib_pointer loc dim typ false 0 (`Offset 0);
  in
  Gl.bind_vertex_array gid;
  Gl.bind_buffer Gl.element_array_buffer iid;
  bind_attrib vid 0 3 Gl.float;
  bind_attrib cid 1 3 Gl.float;
  Gl.bind_vertex_array 0;
  Gl.bind_buffer Gl.array_buffer 0;
  Gl.bind_buffer Gl.element_array_buffer 0;
  Ok (gid, [iid; vid; cid])

let delete_geometry gid bids =
  set_int (Gl.delete_vertex_arrays 1) gid;
  List.iter delete_buffer bids;
  Ok ()

let compile_shader src typ =
  let get_shader sid e = get_int (Gl.get_shaderiv sid e) in
  let sid = Gl.create_shader typ in
  Gl.shader_source sid src;
  Gl.compile_shader sid;
  if get_shader sid Gl.compile_status = Gl.true_ then Ok sid else
  let len = get_shader sid Gl.info_log_length in
  let log = get_string len (Gl.get_shader_info_log sid len None) in
  (Gl.delete_shader sid; Error (`Msg log))

let create_program () =
  compile_shader vertex_shader Gl.vertex_shader >>= fun vid ->
  compile_shader fragment_shader Gl.fragment_shader >>= fun fid ->
  let pid = Gl.create_program () in
  let get_program pid e = get_int (Gl.get_programiv pid e) in
  Gl.attach_shader pid vid; Gl.delete_shader vid;
  Gl.attach_shader pid fid; Gl.delete_shader fid;
  Gl.bind_attrib_location pid 0 "vertex";
  Gl.bind_attrib_location pid 1 "color";
  Gl.link_program pid;
  if get_program pid Gl.link_status = Gl.true_ then Ok pid else
  let len = get_program pid Gl.info_log_length in
  let log = get_string len (Gl.get_program_info_log pid len None) in
  (Gl.delete_program pid; Error (`Msg log))

let delete_program pid =
  Gl.delete_program pid; Ok ()

let draw pid gid win =
  Gl.clear_color 0. 0. 0. 1.;
  Gl.clear Gl.color_buffer_bit;
  Gl.use_program pid;
  Gl.bind_vertex_array gid;
  Gl.draw_elements Gl.triangles 3 Gl.unsigned_byte (`Offset 0);
  Gl.bind_vertex_array 0;
  Sdl.gl_swap_window win;
  Ok ()

let reshape win w h =
  Gl.viewport 0 0 w h

(* Window and OpenGL context *)

let pp_opengl_info ppf () =
  let pp = Format.fprintf in
  let pp_opt ppf = function None -> pp ppf "error" | Some s -> pp ppf "%s" s in
  pp ppf "@[<v>@,";
  pp ppf "Renderer @[<v>@[%a@]@," pp_opt (Gl.get_string Gl.renderer);
  pp ppf "@[OpenGL %a / GLSL %a@]@]@,"
    pp_opt (Gl.get_string Gl.version)
    pp_opt (Gl.get_string Gl.shading_language_version);
  pp ppf "@]"

let create_window ~gl:(maj, min) =
  let w_atts = Sdl.Window.(opengl + resizable) in
  let w_title = Printf.sprintf "OpenGL %d.%d (core profile)" maj min in
  let set a v = Sdl.gl_set_attribute a v in
  set Sdl.Gl.context_profile_mask Sdl.Gl.context_profile_es   >>= fun () ->
  set Sdl.Gl.context_major_version maj                        >>= fun () ->
  set Sdl.Gl.context_minor_version min                        >>= fun () ->
  set Sdl.Gl.doublebuffer 1                                   >>= fun () ->
  Sdl.create_window ~w:640 ~h:480 w_title w_atts              >>= fun win ->
  Sdl.gl_create_context win                                   >>= fun ctx ->
  Sdl.gl_make_current win ctx                                 >>= fun () ->
  Sdl.log "%a" pp_opengl_info ();
  Ok (win, ctx)

let destroy_window win ctx =
  Sdl.gl_delete_context ctx;
  Sdl.destroy_window win;
  Ok ()

(* Event loop *)

let event_loop win draw =
  let e = Sdl.Event.create () in
  let key_scancode e = Sdl.Scancode.enum Sdl.Event.(get e keyboard_scancode) in
  let event e = Sdl.Event.(enum (get e typ)) in
  let window_event e = Sdl.Event.(window_event_enum (get e window_event_id)) in
  let rec loop () =
    Sdl.wait_event (Some e) >>= fun () ->
    match event e with
    | `Quit -> Ok ()
    | `Key_down when key_scancode e = `Escape -> Ok ()
    | `Window_event ->
        begin match window_event e with
        | `Exposed | `Resized ->
            let w, h = Sdl.get_window_size win in
            reshape win w h;
            draw win;
            draw win; (* bug on osx ? *)
            loop ()
        | _ -> loop ()
        end
    | _ -> loop ()
  in
  (draw win; loop ())

(* Main *)

let tri ~gl:(maj, min as gl) =
  Sdl.init Sdl.Init.video          >>= fun () ->
  create_window ~gl                >>= fun (win, ctx) ->
  create_geometry ()               >>= fun (gid, bids) ->
  create_program  ()               >>= fun pid ->
  event_loop win (draw pid gid)    >>= fun () ->
  delete_program pid               >>= fun () ->
  delete_geometry gid bids         >>= fun () ->
  destroy_window win ctx           >>= fun () ->
  Sdl.quit ();
  Ok ()

let main () =
  let exec = Filename.basename Sys.executable_name in
  let usage = str "Usage: %s [OPTION]\n Tests Tgles3.\nOptions:" exec in
  let options = [] in
  let anon _ = raise (Arg.Bad "no arguments are supported") in
  Arg.parse (Arg.align options) anon usage;
  match tri ~gl:(3, 0) with
  | Ok () -> exit 0
  | Error (`Msg msg) -> Sdl.log "%s@." msg; exit 1

let () = main ()
