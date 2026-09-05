(** The Stage A suite:  the parser round trip over every fixture.

    For each ".kan" file of the directory, sorted:  parse it, print the
    tree, parse the printed text, and compare the two item lists.  The
    printer of SA-D2 claims its output re-parses to an equal value, and
    this suite is that claim's only reader at Stage A.

    One argument, the fixtures directory;  [fixtures_default] when the
    argument list is empty.  The suite never leaves the result track:
    it throws no OCaml failure of its own, and the two stdlib file
    calls that can fail pass through the one boundary [attempt_sys]
    below, which reports the failure as a FAIL line (SA-D19).

    The two item lists compare with the structural equality of the
    stdlib.  Both are first-order values built by the parser out of
    strings, integers, quantities and constructors, with no functional
    value and no cycle inside, so the comparison is total.  Nineteen
    term constructors make a written-out pairwise equality impossible
    without the wildcard arm that plan section 11 bans, which is the
    second reason (SA-D20). *)

let fixtures_default : string = "test/fixtures"

(** The one catch site of the whole repository, the single [try] that
    turns an OCaml failure into a result (SA-D19, narrowed in fix round
    1).  [In_channel.with_open_bin] and [Sys.readdir] are
    the only two stdlib calls this suite makes that can fail, and both
    report the failure as [Sys_error];  the OCaml 5.2 standard library
    offers no total form of either call, and brief section 3.10 orders
    the suite to turn a file read error into a FAIL line rather than to
    abort.  So the conversion happens here, once, and every other line
    of kanon stays on the result track.  [Sys_error] is the only caught
    constructor:  a failure of any other kind still leaves the process,
    because hiding it would make a broken suite look green.

    Grep guard:  this is the only [try] in lib/, surface/, bin/ and
    test/, and gate SA-G8 of the brief does not look for the word, so
    the count is held by this comment and by the audit of fix round 1. *)
let attempt_sys (thunk : unit -> 'a) : ('a, string) result =
  try Ok (thunk ()) with Sys_error m -> Error m

let read_file (path : string) : (string, string) result =
  attempt_sys (fun () -> In_channel.with_open_bin path In_channel.input_all)

let kan_files (dir : string) : (string list, string) result =
  attempt_sys (fun () -> Sys.readdir dir)
  |> Result.map (fun (entries : string array) ->
         Array.to_list entries
         |> List.filter (fun (n : string) -> Filename.check_suffix n ".kan")
         |> List.sort String.compare)

(** The round trip for one file:  text, tree, text, tree. *)
let round_trip (path : string) : (unit, string) result =
  let ( let* ) = Result.bind in
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

let report (dir : string) (file : string) : bool =
  let name = Filename.remove_extension file in
  round_trip (Filename.concat dir file)
  |> Result.fold
       ~ok:(fun () ->
         print_string (Printf.sprintf "PARSE %s OK\n" name);
         true)
       ~error:(fun (m : string) ->
         print_string (Printf.sprintf "PARSE %s FAIL: %s\n" name m);
         false)

let run (dir : string) (files : string list) : unit =
  let total = List.length files in
  let passed =
    List.fold_left (fun acc file -> if report dir file then acc + 1 else acc) 0 files
  in
  match () with
  | () when Int.equal passed total && total > 0 ->
      print_string (Printf.sprintf "PARSE-OK %d/%d\n" passed total);
      exit 0
  | () ->
      print_string (Printf.sprintf "PARSE-FAIL %d/%d\n" passed total);
      exit 1

let () =
  let dir =
    match Array.to_list Sys.argv with
    | _prog :: d :: _rest -> d
    | [] -> fixtures_default
    | [ _only ] -> fixtures_default
  in
  kan_files dir
  |> Result.fold
       ~ok:(fun (files : string list) -> run dir files)
       ~error:(fun (m : string) ->
         print_string (Printf.sprintf "PARSE %s FAIL: %s\n" dir m);
         print_string "PARSE-FAIL 0/0\n";
         exit 1)
