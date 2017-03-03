(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup

(* All this is all a bit retired.
   See http://caml.inria.fr/mantis/view.php?id=6704 *)

let symtable_exn_to_string exn =
  (* Pattern match over Symtable.Error and Symtable.exception type
     to emulate Symtable.report_error. See bytecomp/symtable.ml in
     the compiler. *)
  let e = Obj.field (Obj.repr exn) 1 in
  let str e = (Obj.magic (Obj.field e 0) : string) in
  match Obj.tag e with
  | 0 (* Undefined_global *) ->
      strf "Reference to undefined global `%s'" (str e)
  | 1 (* Unavailable_primitive *) ->
      strf "The external function `%s' is not available" (str e)
  | 3 (* Wrong_vm *) ->
      strf "Cannot find or execute the runtime sytem %s" (str e)
  | 4 (* Uninitialized_global *) ->
      strf "The value of global `%s' is not yet computed" (str e)
  | n ->
      strf "Unknown Symtable.error case (%d) please report a bug to odig" n

let exn_to_string bt e = match Printexc.exn_slot_name e with
| "Symtable.Error" -> symtable_exn_to_string e
| exn -> strf "@[<v>Unknown exception:@,%s@,%a@]" exn Fmt.lines bt

let err_fmt, get_err =
  let buf = Buffer.create 255 in
  let fmt = Format.formatter_of_buffer buf in
  let get () =
    Format.pp_print_flush fmt ();
    let s = Buffer.contents buf in
    Buffer.reset buf; s
  in
  fmt, get

let handle_toploop_api f v =
  try
    let r = f err_fmt v in
    match get_err () with "" -> Ok r | err -> R.error_msg err
  with
  | e ->
      let bt = Printexc.get_backtrace () in
      R.error_msg (exn_to_string bt e)

let handle_err d fpath =
  R.reword_error_msg ~replace:true
    (fun e -> R.msgf "@[<v>%s %a:@,%a@]" d Fpath.pp fpath Fmt.lines e)

let add_inc dir =
  let add fmt dir = Topdirs.dir_directory (Fpath.to_string dir) in
  (handle_toploop_api add dir)
  |> handle_err "include" dir

let rem_inc dir =
  let rem fm dir = Topdirs.dir_directory (Fpath.to_string dir) in
  (handle_toploop_api rem dir)
  |> handle_err "exclude" dir

let load_ml ml =
  (handle_toploop_api Topdirs.dir_use (Fpath.to_string ml))
  |> handle_err "load" ml

let load_obj obj =
  (handle_toploop_api Topdirs.dir_load (Fpath.to_string obj))
  |> handle_err "load" obj


(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli

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
