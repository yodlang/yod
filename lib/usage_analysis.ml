(*
 * SPDX-FileCopyrightText: 2025 Milesime <213074881+milesime@users.noreply.github.com>
 *
 * SPDX-License-Identifier: GPL-3.0-only
 *)

open Ast

module Output = struct
  type error =
    | Undefined of {name: string; loc: loc}
    | Reserved of {name: string; loc: loc}
    | Duplicate of {name: string; loc: loc}
    | ConstructorMismatch of {name: string; arg: bool; loc: loc}

  type[@warning "-37"] warning = Unused of {name: string; loc: loc}

  type t = {mutable errors: error list; mutable warnings: warning list}

  (* Using exceptions for error propagation allows error collection to happen
     transparently throughout the analysis phase. *)
  exception Analysis_error of Reporter.report list

  let output = {errors= []; warnings= []}

  let add_error error = output.errors <- output.errors @ [error]

  let[@warning "-32"] add_warning warning =
    output.warnings <- output.warnings @ [warning]

  (* Error codes are used instead of inline strings to enable
     internationalization and consistent error reporting across the compiler. *)
  let code_of_error = function
    | Undefined _ ->
        1001
    | Reserved _ ->
        1002
    | Duplicate _ ->
        1003
    | ConstructorMismatch _ ->
        1004

  let string_of_error = function
    | Undefined {name; _} ->
        Printf.sprintf "Undefined identifier: \u{201C}%s\u{201D}." name
    | Reserved {name; _} ->
        Printf.sprintf "Reserved identifier: \u{201C}%s\u{201D}." name
    | Duplicate {name; _} ->
        Printf.sprintf "Duplicate identifier: \u{201C}%s\u{201D}." name
    | ConstructorMismatch {name; arg; _} ->
        ( if arg then "Unexpected variant constructor"
          else "Expected a variant constructor" )
        ^ Printf.sprintf " for \u{201C}%s\u{201D}." name

  let loc_of_error = function
    | Undefined {loc; _}
    | Reserved {loc; _}
    | Duplicate {loc; _}
    | ConstructorMismatch {loc; _} ->
        loc

  let code_of_warning = function Unused _ -> 1001

  let string_of_warning = function
    | Unused {name; _} ->
        Printf.sprintf "Unused identifier: \u{201C}%s\u{201D}." name

  let loc_of_warning = function Unused {loc; _} -> loc

  (* We raise errors at the end of analysis rather than immediately to collect
     multiple errors, providing a better developer experience. *)
  let raise_errors () =
    if output.errors <> [] then
      raise
      @@ Analysis_error
           (List.map
              (fun error ->
                Reporter.create_report Reporter.Error (code_of_error error)
                  (string_of_error error) (loc_of_error error) )
              output.errors )

  let report_warnings json =
    output.warnings
    |> List.map (fun warning ->
           Reporter.create_report Reporter.Warning (code_of_warning warning)
             (string_of_warning warning)
             (loc_of_warning warning) )
    |> Reporter.print_reports ~json
end

module Env = struct
  (* Variant definitions track whether they take arguments to catch misuse
     early. *)
  type variant_definition = uid * bool

  type t =
    { values: (string, loc) Hashtbl.t
    ; types: (string, loc) Hashtbl.t
    ; variants: (variant_definition, loc) Hashtbl.t }

  (* Creating new scopes via copying enables lexical scoping while preserving
     visibility of outer scope definitions. *)
  let scope {values; types; variants} =
    { values= Hashtbl.copy values
    ; types= Hashtbl.copy types
    ; variants= Hashtbl.copy variants }

  (* Standard types are built into the language and don’t need explicit
     definition. *)
  let std_types = ["Int"; "Float"; "String"; "Bool"; "Unit"]

  (* Standard library functions are predefined and reserved to ensure consistent
     behavior across all programs. *)
  let std_lib =
    [ "sqrt"
    ; "\u{03C0}"
    ; "map"
    ; "filter"
    ; "foldLeft"
    ; "foldRight"
    ; "printString"
    ; "printNumber"
    ; "clearScreen"
    ; "iter"
    ; "join"
    ; "range"
    ; "sleep"
    ; "nth"
    ; "zip"
    ; "random" ]

  let values env = env.values

  let value_exists env = Hashtbl.mem env.values

  let type_exists env name =
    Hashtbl.mem env.types name || List.mem name std_types

  let variant_exists (env : t) = Hashtbl.mem env.variants

  (* We check for loose variant existence (ignoring argument status) to catch
     name conflicts across variant constructors. *)
  let loose_variant_exists (env : t) name =
    Hashtbl.mem env.variants (name, true)
    || Hashtbl.mem env.variants (name, false)

  (* Underscore-prefixed identifiers are ignored in duplicate checks to support
     the common pattern of marking intentionally unused variables. *)
  let add_value env name loc =
    if List.mem name std_lib then Output.add_error (Output.Reserved {name; loc})
    else if (not (String.starts_with ~prefix:"_" name)) && value_exists env name
    then Output.add_error (Output.Duplicate {name; loc}) ;
    Hashtbl.replace env.values name loc

  let add_type env name loc =
    if List.mem name std_types then
      Output.add_error (Output.Reserved {name; loc})
    else if type_exists env name || loose_variant_exists env name then
      Output.add_error (Output.Duplicate {name; loc}) ;
    Hashtbl.replace env.types name loc

  let add_variant env (name, arg) loc =
    if List.mem name std_types then
      Output.add_error (Output.Reserved {name; loc})
    else if loose_variant_exists env name || type_exists env name then
      Output.add_error (Output.Duplicate {name; loc}) ;
    Hashtbl.replace env.variants (name, arg) loc

  (* Root environment is populated with standard library functions to make them
     visible to all code without requiring imports. *)
  let root =
    let env =
      { values= Hashtbl.create 100
      ; types= Hashtbl.create 100
      ; variants= Hashtbl.create 100 }
    in
    List.iter
      (fun name ->
        Hashtbl.replace env.values name (Lexing.dummy_pos, Lexing.dummy_pos) )
      std_lib ;
    env
end

(* We use a two-pass approach (hoist then analyze) to support forward references
   and mutual recursion without complex dependency analysis. *)
let rec analyze_program ?(json = false) program =
  List.iter (hoist_declaration Env.root) program ;
  List.iter (analyze_declaration Env.root) program ;
  Output.raise_errors () ;
  Output.report_warnings json ;
  program

(* The hoisting phase registers declarations but doesn’t analyze their bodies,
   allowing for forward references in code. *)
and hoist_declaration env = function
  | DComment _ ->
      ()
  | DValueBinding (loc, {id; _}) ->
      Env.add_value env id loc
  | DTypeDefinition (loc, {id; _}) ->
      Env.add_type env id loc
  | DADTDefinition (loc, {id; variants; _}) ->
      Env.add_type env id loc ;
      List.iter
        (fun ({loc; id; typing} : variant) ->
          Env.add_variant env (id, Option.is_some typing) loc )
        variants
  | DFunctionDefinition _ ->
      failwith "Function definitions should be desugared before analysis."

(* The analysis phase checks semantic correctness assuming all declarations have
   already been registered in the environment. *)
and analyze_declaration env = function
  | DComment _ ->
      ()
  | DValueBinding (_, {signature; body; _}) ->
      Option.iter (analyze_typing env) signature ;
      analyze_expression env body
  | DTypeDefinition (_, {id; body}) ->
      analyze_typing ~parent_id:id env body
  | DADTDefinition (loc, {id; polymorphics; variants}) ->
      (* Each ADT creates its own scope for polymorphic type variables. *)
      let adt_env = Env.scope env in
      List.iter (fun p -> Env.add_type adt_env p loc) polymorphics ;
      List.iter
        (fun ({typing; _} : variant) ->
          Option.iter (analyze_typing ~in_adt:true ~parent_id:id adt_env) typing )
        variants
  | DFunctionDefinition _ ->
      failwith "Function definitions should be desugared before analysis."

(* Type analysis uses different rules depending on context (in ADT definition or
   not) to handle recursive types and polymorphic type references. *)
and analyze_typing ?(in_adt = false) ?(parent_id = "") env = function
  | TInt _ | TFloat _ | TBool _ | TString _ | TUnit _ ->
      ()
  | TConstructor (loc, {id; typing}) ->
      if
        id = parent_id
        || not (Env.type_exists env id || Env.loose_variant_exists env id)
      then Output.add_error (Output.Undefined {name= id; loc}) ;
      check_for_constructor_mismatch env id (Option.is_some typing) loc ;
      Option.iter (analyze_typing ~in_adt ~parent_id env) typing
  | TPolymorphic (loc, id) ->
      if in_adt && not (Env.type_exists env id) then
        Output.add_error (Output.Undefined {name= id; loc})
  | TTuple (_, typings) ->
      List.iter (analyze_typing ~in_adt ~parent_id env) typings
  | TList (_, typing) ->
      analyze_typing ~in_adt ~parent_id env typing
  | TFunction (_, {l; r}) ->
      analyze_typing ~in_adt ~parent_id env l ;
      analyze_typing ~in_adt ~parent_id env r

(* Expression analysis checks for undefined variables and proper constructor
   usage while tracking scope boundaries for let bindings and lambda
   expressions. *)
and analyze_expression env = function
  | EInt _ | EFloat _ | EBool _ | EString _ | EUnit _ ->
      ()
  | EConstructor (loc, {id; body}) ->
      if not (Env.type_exists env id || Env.loose_variant_exists env id) then
        Output.add_error (Output.Undefined {name= id; loc}) ;
      check_for_constructor_mismatch env id (Option.is_some body) loc ;
      Option.iter (analyze_expression env) body
  | ELID (loc, id) ->
      if not (Env.value_exists env id) then
        Output.add_error (Output.Undefined {name= id; loc})
  | ETuple (_, expressions) | EList (_, expressions) ->
      List.iter (analyze_expression env) expressions
  | EBinaryOperation (_, {l; r; _}) ->
      analyze_expression env l ; analyze_expression env r
  | EUnaryOperation (_, {body; _}) ->
      analyze_expression env body
  | ELet _ ->
      failwith "Let expressions should be desugared before analysis."
  | EDesugaredLet (_, {binding; body}) ->
      let {loc; id; signature; body= body'} = binding in
      (* Let bindings create a new scope for the body but the binding’s own body
         is analyzed in the outer scope to prevent self-reference. *)
      let let_env = Env.scope env in
      Env.add_value let_env id loc ;
      Option.iter (analyze_typing env) signature ;
      analyze_expression env body' ;
      analyze_expression let_env body
  | EIf (_, {predicate; truthy; falsy}) ->
      analyze_expression env predicate ;
      analyze_expression env truthy ;
      analyze_expression env falsy
  | EMatch (_, {body; cases}) ->
      analyze_expression env body ;
      List.iter (analyze_case env) cases
  | ELambda _ ->
      failwith "Lambda expressions should be desugared before analysis."
  | EDesugaredLambda (_, {parameter; body}) ->
      (* Lambda parameters create a new scope for the lambda body. *)
      let lambda_env = Env.scope env in
      analyze_parameter lambda_env parameter ;
      analyze_expression lambda_env body
  | EApplication (_, {body; argument}) ->
      analyze_expression env body ;
      analyze_expression env argument
  | EExpression (_, {body; signature}) ->
      analyze_expression env body ;
      Option.iter (analyze_typing env) signature

(* Pattern matching analysis requires special handling to track bindings
   introduced in patterns and ensure they’re in scope for guards and case
   bodies. *)
and analyze_case env {pattern; guard; body; _} =
  let case_env = Env.scope env in
  analyze_pattern case_env pattern ;
  Option.iter (analyze_expression case_env) guard ;
  analyze_expression case_env body

and analyze_pattern env = function
  | PInt _ | PFloat _ | PBool _ | PString _ ->
      ()
  | PLID (loc, id) ->
      Env.add_value env id loc
  | PTuple (_, patterns) | PList (_, patterns) | PListSpread (_, patterns) ->
      List.iter (analyze_pattern env) patterns
  | PConstructor (loc, {id; pattern}) ->
      if not (Env.type_exists env id || Env.loose_variant_exists env id) then
        Output.add_error (Output.Undefined {name= id; loc}) ;
      check_for_constructor_mismatch env id (Option.is_some pattern) loc ;
      Option.iter (analyze_pattern env) pattern
  (* For pattern combinaisons, we need to track variables that appear in both
     branches. Only those variables should be considered defined in the case
     body. *)
  | POr (_, {l; r}) ->
      let left_env = Env.scope env in
      let right_env = Env.scope env in
      analyze_pattern left_env l ;
      analyze_pattern right_env r ;
      let left_values = Env.values left_env in
      let right_values = Env.values right_env in
      Hashtbl.iter
        (fun lid loc ->
          if Hashtbl.mem right_values lid then
            Hashtbl.replace (Env.values env) lid loc )
        left_values

and analyze_parameter env = function
  | ALID (loc, id) ->
      Env.add_value env id loc
  | ATuple (_, parameters) ->
      List.iter (analyze_parameter env) parameters

(* Checking for definition mismatches ensures variant constructors are used
   consistently with regards to whether they take arguments. *)
and check_for_constructor_mismatch env id arg loc =
  if Env.loose_variant_exists env id && not (Env.variant_exists env (id, arg))
  then Output.add_error (Output.ConstructorMismatch {name= id; arg; loc})
