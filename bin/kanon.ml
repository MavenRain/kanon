(** The kanon driver.  SA-D4: the executable exists from Stage A with
    spec-count only.  check, emit, run and axioms name Stage E and exit
    64, the usage code, so a caller can tell "this command is not built
    yet" from a check failure, which exits 1 once Stage B lands. *)

let usage () : unit = prerr_endline "usage: kanon check|emit|run|axioms|spec-count [ARGS]"

let stage_e (name : string) : unit =
  prerr_endline (Printf.sprintf "kanon: %s arrives at Stage E" name)

(* A string match cannot be exhaustive without a last arm, so the last arm
   binds the unknown command instead of writing a wildcard. *)
let dispatch (cmd : string) : unit =
  match cmd with
  | "spec-count" -> print_string (Kanon_kernel.Spec_count.print ())
  | "check" | "emit" | "run" | "axioms" ->
      stage_e cmd;
      exit 64
  | _unknown ->
      usage ();
      exit 64

let () =
  match Array.to_list Sys.argv with
  | [] ->
      usage ();
      exit 64
  | _prog :: rest -> (
      match rest with
      | [] ->
          usage ();
          exit 64
      | cmd :: _args -> dispatch cmd)
