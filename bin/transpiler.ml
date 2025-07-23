(*
 * SPDX-FileCopyrightText: 2025 Milesime <213074881+milesime@users.noreply.github.com>
 *
 * SPDX-License-Identifier: GPL-2.0-only
 *)

open Yod.Ast

(* Using refs to track state across recursive traversals instead of threading
   state through function calls, simplifies the implementation. *)
let first_type = ref true

let first_bind = ref true

(* Pre-allocating a reasonably sized buffer improves performance by avoiding
   frequent reallocations during string construction. *)
let buffer = Buffer.create 4096

let add s = Buffer.add_string buffer s

let add_space () = Buffer.add_char buffer ' '

let add_newline () = Buffer.add_char buffer '\n'

(* Function to add list elements with separators avoids duplicating separator
   handling logic throughout the code and ensures consistent formatting. *)
let add_list sep f = function
  | [] ->
      ()
  | [x] ->
      f x
  | x :: xs ->
      f x ;
      List.iter (fun x -> add sep ; f x) xs

(* Name mangling for identifiers prevents collisions with OCaml keywords and
   preserves special Unicode characters by converting to valid OCaml
   identifiers. *)
let encode_lid = function
  | "_" ->
      "_"
  | "sqrt" ->
      "Float.sqrt"
  | "\u{03C0}" ->
      "Float.pi"
  | "map" ->
      "List.map"
  | "filter" ->
      "List.filter"
  | "foldLeft" ->
      "List.fold_left"
  | "foldRight" ->
      "List.fold_right"
  | "printString" ->
      "print_endline"
  | "printNumber" ->
      {|(Format.printf "%f@.")|}
  | "clearScreen" ->
      {|(ignore (Sys.command "clear"))|}
  | "iter" ->
      "List.iter"
  | "join" ->
      "String.concat"
  | "range" ->
      "(fun n -> List.init (int_of_float n) (fun i -> float_of_int i))"
  | "sleep" ->
      "Unix.sleepf"
  | "nth" ->
      "(fun lst n -> List.nth lst (int_of_float n))"
  | "zip" ->
      "List.combine"
  | "random" ->
      "(Random.float 1.0)"
  | lid ->
      "l" ^ string_of_int (String.hash lid)

(* Hashing identifiers ensures uniqueness while producing valid OCaml
   identifiers, and prefixing with “U”, an uppercase letter, follows the rules
   of OCaml. *)
let encode_uid str = "U" ^ string_of_int (String.hash str)

(* Parenthesizing expressions maintains correct precedence in the generated
   code. *)
let scoped content = add "(" ; content () ; add ")"

(* Type declarations need special handling to generate valid OCaml type
   definitions. *)
let is_type_decl = function
  | DComment _ | DValueBinding _ | DFunctionDefinition _ ->
      false
  | DTypeDefinition _ | DADTDefinition _ ->
      true

(* Entry point detection ensures the main function is placed at the end for
   proper execution order in the generated code. *)
let is_entry_point = function
  | DValueBinding (_, {id; _}) ->
      id = "_"
  | DComment _ | DFunctionDefinition _ | DTypeDefinition _ | DADTDefinition _ ->
      false

(* Program building ensures proper ordering of declarations for valid OCaml: 1.
   Type declarations first (for forward references). 2. Normal bindings (which
   may reference each other via mutual recursion). 3. Entry point last (to
   ensure execution after all definitions are in scope). *)
let rec build_program decls =
  Buffer.clear buffer ;
  first_type := true ;
  first_bind := true ;
  let type_decls, non_type_decls = List.partition is_type_decl decls in
  let entry_point_decls, other_decls =
    List.partition is_entry_point non_type_decls
  in
  let ordered = type_decls @ other_decls @ entry_point_decls in
  List.iter (fun d -> build_declaration d ; add_newline ()) ordered ;
  Buffer.contents buffer

and build_declaration = function
  | DComment _ ->
      ()
  | DValueBinding (_, {id; body; _}) ->
      (* Using “let rec” for the first binding enables mutual recursion for all
         following bindings using “and”. *)
      if id = "_" then add "let"
      else if !first_bind then (
        add "let rec" ;
        first_bind := false )
      else add "and" ;
      add_space () ;
      add @@ encode_lid id ;
      add_space () ;
      add "=" ;
      add_space () ;
      build_expression body
  | DTypeDefinition (_, {id; body}) ->
      if !first_type then (
        add "type" ;
        first_type := false )
      else add "and" ;
      add_space () ;
      add @@ encode_lid id ;
      add_space () ;
      add "=" ;
      add_space () ;
      build_typing body
  | DFunctionDefinition _ ->
      failwith "Function definitions should be desugared before transpiling."
  | DADTDefinition (_, {id; polymorphics; variants}) ->
      if !first_type then (
        add "type" ;
        first_type := false )
      else add "and" ;
      add_space () ;
      List.iter
        (fun p ->
          add "'" ;
          add @@ encode_lid p ;
          add_space () )
        polymorphics ;
      add @@ encode_lid id ;
      add_space () ;
      add "=" ;
      add_space () ;
      add_list " " build_variant variants

and build_parameter = function
  | ALID (_, str) ->
      add @@ encode_lid str
  | ATuple (_, tuple_param) ->
      scoped (fun () -> add_list "," build_parameter tuple_param)

(* Type mapping preserves semantics between source and target languages while
   converting to OCaml’s type system. *)
and build_typing = function
  (* Using float for all numeric types simplifies operations as the type checker
     is not yet ready. *)
  | TInt _ ->
      add "float"
  | TFloat _ ->
      add "float"
  | TString _ ->
      add "string"
  | TBool _ ->
      add "bool"
  | TUnit _ ->
      add "unit"
  | TList (_, t) ->
      build_typing t ; add_space () ; add "list"
  | TTuple (_, ts) ->
      add_list "*" build_typing ts
  | TFunction (_, {l; r}) ->
      build_typing l ; add_space () ; add "->" ; add_space () ; build_typing r
  | TPolymorphic (_, p) ->
      add "'" ;
      add @@ encode_lid p
  | TConstructor (_, {id; typing}) ->
      add @@ encode_lid id ;
      Option.iter
        (fun t -> add_space () ; add "of" ; add_space () ; build_typing t)
        typing

(* Expression conversion maintains semantics while adapting to OCaml’s syntax,
   with special handling for language-specific constructs. *)
and build_expression = function
  | EExpression (_, {body; signature= _}) ->
      scoped (fun () -> build_expression body)
  | EInt (_, str) ->
      float_of_string str |> string_of_float |> add
  | EFloat (_, str) ->
      add str
  | EBool (_, b) ->
      add @@ string_of_bool b
  | EString (_, s) ->
      add "\"" ;
      add @@ String.escaped s ;
      add "\""
  | EUnit _ ->
      add "()"
  | EConstructor (_, {id; body}) ->
      add @@ encode_uid id ;
      Option.iter (fun e -> add_space () ; build_expression e) body
  | ELID (_, id) ->
      add @@ encode_lid id
  | ETuple (_, exprs) ->
      scoped (fun () -> add_list "," build_expression exprs)
  | EList (_, exprs) ->
      add "[" ;
      add_list ";" build_expression exprs ;
      add "]"
  | EBinaryOperation (span, {l; operator; r}) ->
      build_expression l ;
      add_space () ;
      build_binary_operator span operator ;
      add_space () ;
      build_expression r
  | EUnaryOperation (_, {operator; body}) ->
      build_unary_operator operator ;
      add_space () ;
      build_expression body
  | ELet _ ->
      failwith "Let expressions should be desugared before transpiling."
  | EDesugaredLet (_, {binding; body}) ->
      build_binding binding ; build_expression body
  | EIf (_, {predicate; truthy; falsy}) ->
      add "if" ;
      add_space () ;
      build_expression predicate ;
      add_space () ;
      add "then" ;
      add_space () ;
      build_expression truthy ;
      add_space () ;
      add "else" ;
      add_space () ;
      build_expression falsy
  | EMatch (_, {body; cases}) ->
      add "match" ;
      add_space () ;
      build_expression body ;
      add_space () ;
      add "with" ;
      add_space () ;
      add_list " " build_case cases
  | ELambda _ ->
      failwith "Lambda expressions should be desugared before transpiling."
  | EDesugaredLambda (_, {parameter; body}) ->
      add "fun" ;
      add_space () ;
      build_parameter parameter ;
      add_space () ;
      add "->" ;
      add_space () ;
      build_expression body
  | EApplication (_, {body; argument}) ->
      build_expression body ; add_space () ; build_expression argument

(* Binary operators require special handling for type conversion since OCaml
   distinguishes between integer and float operations with different
   operators. *)
and build_binary_operator span = function
  | BPipe ->
      add "|>"
  | BOr ->
      add "||"
  | BAnd ->
      add "&&"
  | BEqual ->
      add "="
  | BNotEqual ->
      add "<>"
  | BGreaterThan ->
      add ">"
  | BGreaterOrEqual ->
      add ">="
  | BLessThan ->
      add "<"
  | BLessOrEqual ->
      add "<="
  | BConcatenate ->
      let report =
        Yod.Reporter.create_report Yod.Reporter.Error 1000
          "The transpiler does not yet support the concatenation operator." span
      in
      Yod.Reporter.print_reports [report] ;
      add "(* ++ *)"
  (* Using float operators since we represent all numbers as floats. *)
  | BAdd ->
      add "+."
  | BSubstract ->
      add "-."
  | BMultiply ->
      add "*."
  | BDivide ->
      add "/."
  | BModulo ->
      add "mod"
  | BExponentiate ->
      add "**"

(* Unary operators also need special handling for numeric operations. *)
and build_unary_operator = function
  | UPlus ->
      add "+."
  | UMinus ->
      add "-."
  | UNot ->
      add "not"

(* OCaml’s binding syntax is used to implement let expressions. *)
and build_binding {id; body; _} =
  add "let" ;
  add_space () ;
  add @@ encode_lid id ;
  add_space () ;
  add "=" ;
  add_space () ;
  build_expression body ;
  add_space () ;
  add "in" ;
  add_space ()

(* Pattern matching syntax closely mirrors OCaml’s own, simplifying the
   translation. *)
and build_case {pattern; guard; body; _} =
  add "|" ;
  add_space () ;
  build_pattern pattern ;
  Option.iter
    (fun e -> add_space () ; add "when" ; add_space () ; build_expression e)
    guard ;
  add_space () ;
  add "->" ;
  add_space () ;
  build_expression body

and build_pattern = function
  | PInt (_, str) ->
      float_of_string str |> string_of_float |> add
  | PFloat (_, str) ->
      add str
  | PBool (_, b) ->
      add @@ string_of_bool b
  | PString (_, s) ->
      add "\"" ;
      add @@ String.escaped s ;
      add "\""
  | PLID (_, lid) ->
      add @@ encode_lid lid
  | PTuple (_, pats) ->
      scoped (fun () -> add_list "," build_pattern pats)
  | PList (_, pats) ->
      add "[" ;
      add_list ";" build_pattern pats ;
      add "]"
  | PListSpread (_, pats) ->
      add_list "::" build_pattern pats
  | PConstructor (_, {id; pattern}) ->
      add @@ encode_uid id ;
      Option.iter (fun p -> add_space () ; build_pattern p) pattern
  | POr (_, {l; r}) ->
      build_pattern l ; add_space () ; add "|" ; add_space () ; build_pattern r

(* ADT variants are translated directly to OCaml’s algebraic data type
   constructors. *)
and build_variant {id; typing; _} =
  add "|" ;
  add_space () ;
  add @@ encode_uid id ;
  Option.iter
    (fun t -> add_space () ; add "of" ; add_space () ; build_typing t)
    typing
