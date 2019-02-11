(*---------------------------------------------------------------------------
   Copyright (c) 2014 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   lit v0.0.0-126-g4058b8a
  ---------------------------------------------------------------------------*)

(* Checkboard texture on a square. *)

open Gg
open Lit
open Useri
open React

let checkboard_raster () =
  let size = `D2 (Size2.v 64. 64.) in
  let sf = Raster.Sample.(format rgb_l `UInt8) in
  let len = Raster.Sample.scalar_count size sf in
  let buf = Ba.create Ba.UInt8 len in
  let img = Raster.v size sf (`UInt8 buf) in
  let i = ref 0 in
  for y = 0 to Raster.hi img - 1 do
    for x = 0 to Raster.wi img - 1 do
      let xm = if x land 8 = 0 then 1 else 0 in
      let ym = if y land 8 = 0 then 1 else 0 in
      let l = (xm lxor ym) * 225 in
      Ba.set_3d buf !i l l l; i := !i + 3
    done
  done;
  img

let checkboard_tex () =
  Tex.create
    ~wrap_s:`Clamp_to_edge ~wrap_t:`Clamp_to_edge
    ~mipmaps:true
    ~min_filter:`Linear_mipmap_linear ~mag_filter:`Linear
    (Tex.init_of_raster (checkboard_raster ()))

let program =
  let checkboard = Uniform.tex "checkboard" (checkboard_tex ()) in
  let uset = Uniform.(empty + model_to_clip "model_to_clip" + checkboard) in
  Prog.create ~uset [
    Prog.shader `Vertex "
     uniform mat4 model_to_clip;
     in vec3 vertex;
     in vec2 tex;
     out vec2 v_tex;
     void main ()
     {
        v_tex = tex;
        gl_Position = model_to_clip * vec4(vertex, 1.0);
     }";

    Prog.shader `Fragment "
    uniform sampler2D checkboard;
    in vec2 v_tex;
    out vec4 f_color;
    void main ()
    {
      f_color = texture(checkboard, v_tex);
    }"
  ]

let effect = Effect.create program

(* World *)

let prim = Litu.Prim.rect ~tex:"tex" (Box2.v_mid P2.o (Size2.v 1. 1.))
let prim_init_rot =
  let z = -0.1 *. Float.pi in
  let y = -0.05 *. Float.pi in
  let x =  0.05 *. Float.pi in
  Quat.rot3_zyx (V3.v z y x)

(* Render *)

let render r _ prim_rot =
  let op = Renderer.op effect ~tr:(M4.of_quat prim_rot) prim in
  Renderer.add_op r op;
  Renderer.render r;
  Surface.update ();
  ()

(* Setup & UI *)

let resize r size =
  let clears = { Fbuf.clears_default with
                 Fbuf.clear_color = Some Color.white }
  in
  let aspect = Size2.w size /. Size2.h size in
  let view =
    let tr = View.look ~at:P3.o ~from:(P3.v 0. 0. 5.) () in
    let fov = `H Float.pi_div_4 in
    let proj = View.persp ~fov ~aspect ~near:1.0 ~far:10. in
    View.create ~tr ~proj ()
  in
  Renderer.set_size r size;
  Renderer.set_view r view;
  Fbuf.set_clears Fbuf.default clears;
  ()

(* Ui *)

let control_rot r init =
  let rot ~init ~start pos =
    let rot = Litu.Manip.rot ~init ~start () in
    let update pos =
      let pt = View.ndc_of_surface (Renderer.view r) pos in
      Litu.Manip.rot_update rot pt
    in
    S.map update pos
  in
  let control =
    let start start init =
      let pt = View.ndc_of_surface (Renderer.view r) start in
      rot ~init ~start:pt Mouse.pos
    in
    let stop pos rot = S.const rot in
    E.select [E.map start Mouse.left_down; E.map stop Mouse.left_up; ]
  in
  S.switch @@
  S.fold (fun rot rotf -> rotf (S.value (* bad *) rot)) (S.const init) control

let setup size =
  let s = S.value size in
  let r = Renderer.create ~size:s (module Lit_gl : Lit.Renderer.T) in
  let resize = S.l1 (resize r) size in
  let prim_rot = control_rot r prim_init_rot in
  let draw = S.sample (render r) Surface.refresh prim_rot in
  Surface.set_refresher (S.changes prim_rot);
  App.sink_signal resize;
  App.sink_event draw;
  r

let main () =
  let hidpi = App.env "HIDPI" ~default:true bool_of_string in
  let size = Size2.v 600. 400. in
  let mode_set = Surface.mode_flip (Key.up `Space) in
  let surface = Surface.create ~hidpi ~size () in
  Surface.set_mode_setter mode_set;
  match App.init ~surface () with
  | Error (`Msg e) -> Printf.eprintf "%s" e; exit 1
  | Ok () ->
      let r = setup Surface.raster_size in
      App.run ~until:App.quit ();
      Renderer.release r;
      exit 0

let () = main ()

(*---------------------------------------------------------------------------
   Copyright (c) 2014 Daniel C. Bünzli

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
