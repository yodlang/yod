(*
 * SPDX-FileCopyrightText: 2025 Milesime <213074881+milesime@users.noreply.github.com>
 *
 * SPDX-License-Identifier: GPL-3.0-only
 *)

type position = Lexing.position =
  {pos_fname: string; pos_lnum: int; pos_bol: int; pos_cnum: int}

and loc = position * position

and uid = string

and lid = string

and program = declaration list

and declaration =
  | DComment of string
  | DValueBinding of loc * binding
  | DTypeDefinition of loc * type_definition
  | DFunctionDefinition of loc * function_definition
  | DADTDefinition of loc * adt_definition

and type_definition = {id: uid; body: typing}

and function_definition =
  {id: lid; parameters: parameter list; signature: signature; body: expression}

and adt_definition = {id: uid; polymorphics: string list; variants: variant list}

and binding = {loc: loc; id: lid; signature: signature; body: expression}

and signature = typing option

and parameter = ALID of loc * lid | ATuple of loc * parameter list

and typing =
  | TInt of loc
  | TFloat of loc
  | TBool of loc
  | TString of loc
  | TUnit of loc
  | TConstructor of loc * typing_constructor
  | TPolymorphic of loc * string
  | TTuple of loc * typing list
  | TList of loc * typing
  | TFunction of loc * function_typing

and typing_constructor = {id: uid; typing: typing option}

and function_typing = {l: typing; r: typing}

and expression =
  | EInt of loc * string
  | EFloat of loc * string
  | EBool of loc * bool
  | EString of loc * string
  | EUnit of loc
  | EConstructor of loc * constructor
  | ELID of loc * lid
  | ETuple of loc * expression list
  | EList of loc * expression list
  | EBinaryOperation of loc * binary_operation
  | EUnaryOperation of loc * unary_operation
  | ELet of loc * let_expr
  | EDesugaredLet of loc * desugared_let_expr
  | EIf of loc * if_expr
  | EMatch of loc * match_expr
  | ELambda of loc * lambda_expr
  | EDesugaredLambda of loc * desugared_lambda_expr
  | EApplication of loc * application
  | EExpression of loc * expression_with_signature

and constructor = {id: uid; body: expression option}

and binary_operation = {l: expression; operator: binary_operator; r: expression}

and unary_operation = {operator: unary_operator; body: expression}

and let_expr = {bindings: binding list; body: expression}

and desugared_let_expr = {binding: binding; body: expression}

and if_expr = {predicate: expression; truthy: expression; falsy: expression}

and match_expr = {body: expression; cases: case list}

and lambda_expr = {parameters: parameter list; body: expression}

and desugared_lambda_expr = {parameter: parameter; body: expression}

and application = {body: expression; argument: expression}

and expression_with_signature = {body: expression; signature: signature}

and binary_operator =
  | BPipe
  | BOr
  | BAnd
  | BEqual
  | BNotEqual
  | BGreaterThan
  | BGreaterOrEqual
  | BLessThan
  | BLessOrEqual
  | BConcatenate
  | BAdd
  | BSubstract
  | BMultiply
  | BDivide
  | BModulo
  | BExponentiate

and unary_operator = UPlus | UMinus | UNot

and variant = {loc: loc; id: uid; typing: typing option}

and case =
  {loc: loc; pattern: pattern; guard: expression option; body: expression}

and pattern =
  | PInt of loc * string
  | PFloat of loc * string
  | PBool of loc * bool
  | PString of loc * string
  | PLID of loc * lid
  | PTuple of loc * pattern list
  | PList of loc * pattern list
  | PListSpread of loc * pattern list
  | PConstructor of loc * constructor_pattern
  | POr of loc * or_pattern

and constructor_pattern = {id: uid; pattern: pattern option}

and or_pattern = {l: pattern; r: pattern} [@@deriving show {with_path= false}]
