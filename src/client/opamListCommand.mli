(**************************************************************************)
(*                                                                        *)
(*    Copyright 2012-2015 OCamlPro                                        *)
(*    Copyright 2012 INRIA                                                *)
(*                                                                        *)
(*  All rights reserved. This file is distributed under the terms of the  *)
(*  GNU Lesser General Public License version 2.1, with the special       *)
(*  exception on linking described in the file LICENSE.                   *)
(*                                                                        *)
(**************************************************************************)

(** Functions handling the "opam list" subcommand *)

open OpamTypes
open OpamStateTypes

(** Switches to determine what to include when querying (reverse)
    dependencies *)
type dependency_toggles = {
  recursive: bool;
  depopts: bool;
  build: bool;
  test: bool;
  doc: bool;
  dev: bool;
}

val default_dependency_toggles: dependency_toggles

type pattern_selector = {
  case_sensitive: bool;
  exact: bool;
  glob: bool;
  fields: string list;
  ext_fields: bool; (** Match on raw strings in [x-foo] fields *)
}

val default_pattern_selector: pattern_selector

(** Package selectors used to filter the set of packages *)
type selector =
  | Any
  | Installed
  | Root
  | Compiler
  | Available
  | Installable
  | Pinned
  | Depends_on of dependency_toggles * atom list
  | Required_by of dependency_toggles * atom list
  | Solution of dependency_toggles * atom list
  | Pattern of pattern_selector * string
  | Atoms of atom list
  | Flag of package_flag
  | From_repository of repository_name list

(** Applies a formula of selectors to filter the package from a given switch
    state *)
val filter:
  base:package_set -> 'a switch_state ->
  selector OpamFormula.formula -> package_set

(** Lists the external dependencies matching the given flags for the given set
    of packages *)
val print_depexts: 'a switch_state -> package_set -> string list -> unit

(** Element of package information to be printed *)
type output_format =
  | Name               (** Name without version *)
  | Version            (** Version of the currently looked-at package *)
  | Package            (** [name.version] *)
  | Synopsis           (** One-line package description *)
  | Synopsis_or_target (** Pinning target if pinned, synopsis otherwise *)
  | Description        (** The package description, excluding synopsis *)
  | Field of string    (** The value of the given opam-file field *)
  | Installed_version  (** Installed version or "--" if none *)
  | Pinning_target     (** Empty string if not pinned *)
  | Raw                (** The full contents of the opam file (reformatted) *)
  | All_installed_versions (** List of the installed versions in all switches
                               with the corresponding switches in brackets *)
  | Available_versions (** List of the available versions (currently installed
                           one in bold if color enabled) *)
  | All_versions       (** List of the existing package versions (installed,
                           installed in current switch and unavailable colored
                           specifically if color enabled) *)
  | Repository         (** The repository the package was found in (may be empty
                           for pinned packages) *)
  | Installed_files    (** The list of files that the installed package added to
                           the system *)

val default_list_format: output_format list

(** Gets either the current switch state, if a switch is selected, or a virtual
    state corresponding to the configured repos *)
val get_switch_state: 'a global_state -> unlocked switch_state

(** For documentation, includes a dummy '<field>:' for the [Field] format *)
val field_names: (output_format * string) list

val string_of_field: output_format -> string

val field_of_string: string -> output_format


(** Outputs a list of packages as a table according to the formatting options.
    [normalise] supersedes [prettify] and uses a canonical way of displaying
    package definition file fields. [prettify] uses a nicer to read format for the
    package definition file fields. *)
val display:
  'a switch_state ->
  header:bool ->
  format:output_format list ->
  dependency_order:bool ->
  all_versions:bool ->
  ?separator:string ->
  ?prettify:bool ->
  ?normalise:bool ->
  package_set -> unit

(** Display all available packages that match any of the regexps. *)
val list:
  'a global_state ->
  print_short:bool ->
  filter:[`all|`installed|`roots|`installable] ->
  order:[`normal|`depends] ->
  exact_name:bool ->
  case_sensitive:bool ->
  ?depends:(atom list) ->
  ?reverse_depends:bool -> ?recursive_depends:bool -> ?resolve_depends:bool ->
  ?depopts:bool -> ?depexts:string list -> ?dev:bool ->
  string list ->
  unit

(** Display a general summary of a collection of packages. *)
val info:
  'a global_state ->
  fields:string list -> raw_opam:bool -> where:bool ->
  ?normalise:bool -> ?show_empty:bool ->
  atom list -> unit

(** Prints the value of an opam field in a shortened way (with [prettify] -- the
    default -- puts lists of strings in a format that is easier to read *)
val mini_field_printer: ?prettify:bool -> ?normalise:bool -> value -> string

val string_of_formula: selector OpamFormula.formula -> string
