(* $Id$ *)

open Misc
open Gdk

type color = [
  | `COLOR of Color.t
  | `WHITE
  | `BLACK
  | `NAME of string
  | `RGB of int * int * int
]

let color : color -> Color.t = function
    `COLOR col -> col
  | `WHITE|`BLACK|`NAME _|`RGB _ as def -> Color.alloc def

class ['a] drawing w = object
  val gc = GC.create w
  val w : 'a drawable = w
  method set_foreground col = GC.set_foreground gc (color col)
  method set_background col = GC.set_background gc (color col)
  method set_line_attributes = GC.set_line_attributes gc
  method point = Draw.point w gc
  method line = Draw.line w gc
  method rectangle = Draw.rectangle w gc
  method arc = Draw.arc w gc
  method polygon ?filled l = Draw.polygon w gc ?filled l
  method string s = Draw.string w gc ~string:s
  method image image = Draw.image w gc ~image
end

class pixmap ?mask pm = object
  inherit [[`pixmap]] drawing pm as pixmap
  val bitmap = may_map mask ~f:(new drawing)
  val mask : bitmap option = mask
  method pixmap = w
  method mask = mask
  method point ~x ~y =
    pixmap#point ~x ~y;
    may bitmap ~f:(fun m -> m#point ~x ~y)
  method line ~x ~y ~x:x' ~y:y' =
    pixmap#line ~x ~y ~x:x' ~y:y';
    may bitmap ~f:(fun m -> m#line ~x ~y ~x:x' ~y:y')
  method rectangle ~x ~y ~width ~height ?filled () =
    pixmap#rectangle ~x ~y ~width ~height ?filled ();
    may bitmap ~f:(fun m -> m#rectangle ~x ~y ~width ~height ?filled ())
  method arc ~x ~y ~width ~height ?filled ?start ?angle () =
    pixmap#arc ~x ~y ~width ~height ?filled ?start ?angle ();
    may bitmap
      ~f:(fun m -> m#arc ~x ~y ~width ~height ?filled ?start ?angle ());
  method polygon ?filled l =
    pixmap#polygon ?filled l;
    may bitmap ~f:(fun m -> m#polygon ?filled l)
  method string s ~font ~x ~y =
    pixmap#string s ~font ~x ~y;
    may bitmap ~f:(fun m -> m#string s ~font ~x ~y)
end

let pixmap ~window ~width ~height =
  window#misc#realize ();
  new pixmap (Pixmap.create window#misc#window
		~width ~height ~depth:window#misc#visual_depth)

let pixmap_from_xpm ~window ~file ?colormap ?transparent () =
  let pm, mask =
    try Pixmap.create_from_xpm window ~file ?colormap
	?transparent:(may_map transparent ~f:color)
    with Null_pointer -> invalid_arg "GdkObj.pixmap_from_xpm" in
  new pixmap pm ~mask

let pixmap_from_xpm_d ~window ~data ?colormap ?transparent () =
  let pm, mask =
    Pixmap.create_from_xpm_d window ~data ?colormap
      ?transparent:(may_map transparent ~f:color) in
  new pixmap pm ~mask

class drag_context context = object
  val context = context
  method status ?(time=0) act = Gdk.DnD.drag_status context act ~time
  method suggested_action = Gdk.DnD.drag_context_suggested_action context
  method targets = Gdk.DnD.drag_context_targets context
end
