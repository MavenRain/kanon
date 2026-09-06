(** The M0 kernel suite (brief section 3.11).  Five groups run in one
    order and each prints its own count, then one verdict line closes
    the run:

    - PARSE, the round trip of Stage A, over every ".kan" file of
      fixtures/ and of neg/;
    - CHECK, one line per positive fixture, where OK means the file
      elaborates, checks, and prints the byte for byte text of
      golden/NAME.checked;
    - ERASE, one line per positive fixture, where OK means the same
      file erases and prints the byte for byte text of
      golden/NAME.erased (Stage C, brief section 3.6);
    - NEG, one line per negative, where OK means the file fails and
      [Error.message] equals the single line of neg/NAME.err;
    - KNEG, the shapes M0 declares and does not admit, reached from
      OCaml because no surface production spells them.

    One argument, the test root, not the fixtures directory (SB-D15);
    [root_default] when the argument list is empty.  The suite never
    leaves the result track:  it throws no OCaml failure of its own,
    and the stdlib file calls that can fail pass through the one
    boundary [attempt_sys] below, which reports the failure as a FAIL
    line (SA-D19).

    A FAIL line carries its reason after a colon, in every group, so a
    mutation run reads why a fixture died and not only that it did
    (SB-D36).  The count lines and the verdict line hold the shape the
    gates read. *)

let root_default : string = "test"

(** The file boundary moved to test/sys_io.ml at Stage D (SD-D14).  Two
    runners live under test/ from Stage D on, main.exe and wasm.exe, and
    both read files;  one catch site serves both, so the repository still
    holds exactly one of them, which gate SD-G11 of the brief reads. *)
let read_file : string -> (string, string) result = Sys_io.read_file

(** The ".kan" files of a directory, sorted, without the extension. *)
let kan_names : string -> (string list, string) result = Sys_io.kan_names

let path_of (dir : string) (name : string) (ext : string) : string =
  Filename.concat dir (name ^ ext)

let ( let* ) = Result.bind

(** The round trip for one file:  text, tree, text, tree. *)
let round_trip (path : string) : (unit, string) result =
  let* src = read_file path in
  let* first =
    Kanon_surface.Parser.parse src |> Result.map_error Kanon_kernel.Error.message
  in
  let printed = Kanon_surface.Syntax.print first in
  let* second =
    Kanon_surface.Parser.parse printed |> Result.map_error Kanon_kernel.Error.message
  in
  if first = second then Ok ()
  else Error "the printed text parses to a different tree"

(** A positive fixture:  it checks, and its checked form is the golden
    text byte for byte. *)
let check_fixture (root : string) (name : string) : (unit, string) result =
  let* src = read_file (path_of (Filename.concat root "fixtures") name ".kan") in
  let* golden = read_file (path_of (Filename.concat root "golden") name ".checked") in
  let* rows =
    Kanon_surface.Elab.check_text Kanon_kernel.Global.initial src
    |> Result.map_error Kanon_kernel.Error.to_string
  in
  let printed = Kanon_surface.Elab.checked_form rows in
  if String.equal printed golden then Ok ()
  else Error "the checked form is not the golden text"

(** A positive fixture at the erasure:  it checks, it erases in the
    globals it was checked in, and the erased program is the golden
    text byte for byte.  The suite reads the same text the driver
    prints, because both call [Erase.print] of [Erase.program]
    (SC-D1). *)
let erase_fixture (root : string) (name : string) : (unit, string) result =
  let* src = read_file (path_of (Filename.concat root "fixtures") name ".kan") in
  let* golden = read_file (path_of (Filename.concat root "golden") name ".erased") in
  let* rows =
    Kanon_surface.Elab.check_text Kanon_kernel.Global.initial src
    |> Result.map_error Kanon_kernel.Error.to_string
  in
  let* out =
    Kanon_kernel.Erase.program Kanon_kernel.Global.initial rows
    |> Result.map_error Kanon_kernel.Error.to_string
  in
  let printed = Kanon_kernel.Erase.print out in
  if String.equal printed golden then Ok ()
  else Error "the erased form is not the golden text"

(** A negative:  it fails, and the failure is the one the sidecar
    names.  The sidecar holds one line, so its trailing newline is
    dropped before the comparison. *)
let check_negative (root : string) (name : string) : (unit, string) result =
  let dir = Filename.concat root "neg" in
  let* src = read_file (path_of dir name ".kan") in
  let* want = read_file (path_of dir name ".err") in
  Kanon_surface.Elab.check_text Kanon_kernel.Global.initial src
  |> Result.fold
       ~ok:(fun (_rows : (string * Kanon_kernel.Global.entry) list) ->
         Error "the file checks and the negative expects it to fail")
       ~error:(fun (e : Kanon_kernel.Error.t) ->
         let got = Kanon_kernel.Error.message e in
         if String.equal got (String.trim want) then Ok ()
         else Error (Printf.sprintf "the message is \"%s\"" got))

(** The shapes M0 declares and does not admit.  No surface production
    spells [SMu], so the term is built here, and the kernel answers
    with the milestone that brings it. *)
let kneg_smu () : (unit, string) result =
  let shape : Kanon_kernel.Term.t Kanon_kernel.Shape.t =
    Kanon_kernel.Shape.SMu ("F", [ Kanon_kernel.Term.Univ Kanon_kernel.Level.zero ])
  in
  let diagram : Kanon_kernel.Term.t =
    Kanon_kernel.Term.Sec (Kanon_kernel.Shape.SColl 0, [])
  in
  Kanon_kernel.Check.infer_term Kanon_kernel.Global.initial
    (Kanon_kernel.Term.Lan (shape, diagram))
  |> Result.fold
       ~ok:(fun (_v : Kanon_kernel.Value.t) -> Error "the SMu shape is admitted at M0")
       ~error:(fun (e : Kanon_kernel.Error.t) ->
         let got = Kanon_kernel.Error.message e in
         if String.equal got "SMu arrives at M1" then Ok ()
         else Error (Printf.sprintf "the message is \"%s\"" got))

(** The totality guard of M1, reached from OCaml because no surface
    production spells a self reference:  the elaborator refuses one as
    unbound before the guard can read it (SB-D24, n07), so the term is
    built here.  [guard] is not wired into the check path at M0
    (SC-D15). *)
let kneg_self () : (unit, string) result =
  Kanon_kernel.Totality.guard Kanon_kernel.Global.initial "self"
    (Kanon_kernel.Term.Global "Nat") (Kanon_kernel.Term.Global "self")
  |> Result.fold
       ~ok:(fun (_g : int option) ->
         Error "the self reference is admitted at M0")
       ~error:(fun (e : Kanon_kernel.Error.t) ->
         let got = Kanon_kernel.Error.message e in
         if String.equal got "structural recursion arrives at M1" then Ok ()
         else Error (Printf.sprintf "the message is \"%s\"" got))

(** The KNEG rows by name, so the group reads one list of names as
    every other group does. *)
let kneg (name : string) : (unit, string) result =
  match name with
  | "smu" -> kneg_smu ()
  | "self" -> kneg_self ()
  | other -> Error (Printf.sprintf "no kernel negative is named \"%s\"" other)

(** One line of a group, and whether it passed. *)
let report (kind : string) (name : string) (r : (unit, string) result) : bool =
  r
  |> Result.fold
       ~ok:(fun () ->
         print_string (Printf.sprintf "%s %s OK\n" kind name);
         true)
       ~error:(fun (m : string) ->
         print_string (Printf.sprintf "%s %s FAIL: %s\n" kind name m);
         false)

(** Run one group and print its count line.  The answer is the pair of
    the passing count and the total, which the verdict folds. *)
let group (kind : string) (label : string) (run : string -> (unit, string) result)
    (names : string list) : int * int =
  let passed =
    List.fold_left
      (fun (acc : int) (name : string) ->
        if report kind name (run name) then acc + 1 else acc)
      0 names
  in
  let total = List.length names in
  print_string (Printf.sprintf "%s %d/%d\n" label passed total);
  (passed, total)

(** PARSE prints its count alone:  a passing round trip says nothing,
    because eighteen positives and eight negatives would otherwise
    print twenty six lines that carry no reading (SB-D35). *)
let parse_group (dirs : (string * string list) list) : int * int =
  let files =
    List.concat_map
      (fun ((dir : string), (names : string list)) ->
        List.map (fun (name : string) -> (dir, name)) names)
      dirs
  in
  let passed =
    List.fold_left
      (fun (acc : int) ((dir : string), (name : string)) ->
        round_trip (path_of dir name ".kan")
        |> Result.fold
             ~ok:(fun () -> acc + 1)
             ~error:(fun (m : string) ->
               print_string (Printf.sprintf "PARSE %s FAIL: %s\n" name m);
               acc))
      0 files
  in
  let total = List.length files in
  print_string (Printf.sprintf "PARSE-OK %d/%d\n" passed total);
  (passed, total)

let full ((passed : int), (total : int)) : bool = Int.equal passed total && total > 0

let verdict (groups : (int * int) list) : unit =
  match () with
  | () when List.for_all full groups ->
      print_string "SUITE-KERNEL OK\n";
      exit 0
  | () ->
      print_string "SUITE-KERNEL FAIL\n";
      exit 1

let run (root : string) (fixtures : string list) (negatives : string list) : unit =
  let fixtures_dir = Filename.concat root "fixtures" in
  let neg_dir = Filename.concat root "neg" in
  let parsed = parse_group [ (fixtures_dir, fixtures); (neg_dir, negatives) ] in
  let checked = group "CHECK" "CHECK-OK" (check_fixture root) fixtures in
  let erased = group "ERASE" "ERASE-OK" (erase_fixture root) fixtures in
  let refused = group "NEG" "NEG-OK" (check_negative root) negatives in
  let closed = group "KNEG" "KNEG-OK" kneg [ "smu"; "self" ] in
  verdict [ parsed; checked; erased; refused; closed ]

let fail_out (m : string) : unit =
  print_string (Printf.sprintf "SUITE %s\n" m);
  print_string "SUITE-KERNEL FAIL\n";
  exit 1

let () =
  let root =
    match Array.to_list Sys.argv with
    | _prog :: d :: _rest -> d
    | [] -> root_default
    | [ _only ] -> root_default
  in
  let listed =
    let* fixtures = kan_names (Filename.concat root "fixtures") in
    let* negatives = kan_names (Filename.concat root "neg") in
    Ok (fixtures, negatives)
  in
  listed
  |> Result.fold
       ~ok:(fun (((fixtures : string list), (negatives : string list))) ->
         run root fixtures negatives)
       ~error:fail_out
