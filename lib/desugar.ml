(*
 * SPDX-FileCopyrightText: 2025 Milesime <213074881+milesime@users.noreply.github.com>
 *
 * SPDX-License-Identifier: GPL-2.0-only
 *)

open Ast

let rec desugar_program program = List.map desugar_declaration program

and desugar_declaration decl =
  match decl with
  (* These declarations don’t contain expressions that need desugaring. *)
  | DComment _ | DTypeDefinition _ | DADTDefinition _ ->
      decl
  | DValueBinding (loc, binding) ->
      DValueBinding (loc, desugar_binding binding)
  (* Function definitions are transformed into lambda value bindings for uniform
     treatment. *)
  | DFunctionDefinition (loc, f) ->
      desugar_function_definition loc f

and desugar_binding binding =
  {binding with body= desugar_expression binding.body}

and desugar_function_definition loc {id; parameters; signature; body} =
  (* Converting function definitions to value bindings with lambda expressions
     simplifies later stages by unifying function representation. *)
  DValueBinding
    (loc, {loc; id; signature; body= desugar_lambda loc parameters body})

and desugar_lambda loc parameters body =
  match parameters with
  | [] ->
      desugar_expression body
  (* Building lambdas one parameter at a time enables currying. *)
  | p :: tail ->
      EDesugaredLambda (loc, {parameter= p; body= desugar_lambda loc tail body})

and desugar_expression expr =
  match expr with
  (* Primitive expressions and already desugared forms need no
     transformation. *)
  | EInt _
  | EFloat _
  | EBool _
  | EString _
  | EUnit _
  | ELID _
  | EDesugaredLambda _
  | EDesugaredLet _ ->
      expr
  | EConstructor (loc, {id; body}) ->
      EConstructor (loc, {id; body= Option.map desugar_expression body})
  | ETuple (loc, exprs) ->
      ETuple (loc, List.map desugar_expression exprs)
  | EList (loc, exprs) ->
      EList (loc, List.map desugar_expression exprs)
  | EBinaryOperation (loc, {l; operator; r}) ->
      EBinaryOperation
        (loc, {l= desugar_expression l; operator; r= desugar_expression r})
  | EUnaryOperation (loc, {operator; body}) ->
      EUnaryOperation (loc, {operator; body= desugar_expression body})
  (* Let expressions are transformed into nested desugared let forms to simplify
     later processing and maintain lexical scoping. *)
  | ELet (loc, {bindings; body}) ->
      desugar_let loc bindings body
  | EIf (loc, {predicate; truthy; falsy}) ->
      EIf
        ( loc
        , { predicate= desugar_expression predicate
          ; truthy= desugar_expression truthy
          ; falsy= desugar_expression falsy } )
  | EMatch (loc, {body; cases}) ->
      EMatch
        ( loc
        , {body= desugar_expression body; cases= List.map desugar_case cases} )
  (* Lambda expressions are converted to the desugared form to normalize
     representation. *)
  | ELambda (loc, {parameters; body}) ->
      desugar_lambda loc parameters body
  | EApplication (loc, {body; argument}) ->
      EApplication
        ( loc
        , {body= desugar_expression body; argument= desugar_expression argument}
        )
  | EExpression (loc, {body; signature}) ->
      EExpression (loc, {body= desugar_expression body; signature})

and desugar_let loc bindings body =
  match bindings with
  | [] ->
      desugar_expression body
  (* Transforming multi-binding let expressions into nested single-binding lets
     preserves correct scoping while simplifying the internal representation. *)
  | b :: tail ->
      EDesugaredLet
        (loc, {binding= desugar_binding b; body= desugar_let loc tail body})

and desugar_case case =
  { case with
    guard= Option.map desugar_expression case.guard
  ; body= desugar_expression case.body }
