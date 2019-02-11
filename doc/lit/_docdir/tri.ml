(*---------------------------------------------------------------------------
   Copyright (c) 2014 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   lit v0.0.0-126-g4058b8a
  ---------------------------------------------------------------------------*)

(* Draws a tri-colored triangle.

   Compile with
   ocamlfind ocamlopt -package tgls.tgl3,lit.gl,useri.tsdl,useri -linkpkg \
      tri.ml -o tri.native *)

open Gg
open Lit
open Useri
open React

let triangle () =
  let b = Buf.create (`Cpu (`Float32, 3 * 3 + 3 * 4)) in
  let vertices = Attr.create Attr.vertex ~dim:3 b in
  let colors = Attr.create Attr.color ~dim:4 ~first:(3 * 3) b in
  let prim = Prim.create ~count:3 `Triangles [vertices; colors] in
  let b = Buf.get_cpu b Ba.Float32 in
  Ba.set_3d b 0  (-0.8) (-0.8) ( 0.0);  (* vertices *)
  Ba.set_3d b 3  ( 0.8) (-0.8) ( 0.0);
  Ba.set_3d b 6  ( 0.0) ( 0.8) ( 0.0);
  Ba.set_v4 b 9  Color.red;             (* colors *)
  Ba.set_v4 b 13 Color.green;
  Ba.set_v4 b 17 Color.blue;
  prim

let program =
  Prog.create [
    Prog.shader `Vertex "
    in vec3 vertex;
    in vec4 color;
    out vec4 v_color;
    void main()
    {
        v_color = color;
        gl_Position = vec4(vertex, 1.0);
    }";

    Prog.shader `Fragment "
      in vec4 v_color;
      out vec4 color;
      void main () { color = v_color; }"
  ]

let effect = Effect.create program

let op = Renderer.op effect (triangle ())

(* Render *)

let size = V2.v 600. 400.

let render r _ =
  Renderer.add_op r op;
  Renderer.render r;
  Surface.update ();
  ()

let setup size =
  let s = S.value size in
  let r = Renderer.create ~size:s (module Lit_gl : Lit.Renderer.T) in
  let resize = S.l1 (Renderer.set_size r) size in
  let draw = E.map (render r) Surface.refresh in
  App.sink_signal resize;
  App.sink_event draw;
  r

let main () =
  let hidpi = App.env "HIDPI" ~default:true bool_of_string in
  let size = Size2.v 600. 400. in
  let surface = Surface.create ~hidpi ~size () in
  let mode_set = Surface.mode_flip (Key.up `Space) in
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
