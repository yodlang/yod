(*
 * SPDX-FileCopyrightText: 2025 Milesime <213074881+milesime@users.noreply.github.com>
 *
 * SPDX-License-Identifier: GPL-2.0-only
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

and or_pattern = {l: pattern; r: pattern}

val pp_position : Format.formatter -> position -> unit

val show_position : position -> string

val pp_loc : Format.formatter -> loc -> unit

val show_loc : loc -> string

val pp_uid : Format.formatter -> uid -> unit

val show_uid : uid -> string

val pp_lid : Format.formatter -> lid -> unit

val show_lid : lid -> string

val pp_program : Format.formatter -> program -> unit

val show_program : program -> string

val pp_declaration : Format.formatter -> declaration -> unit

val show_declaration : declaration -> string

val pp_type_definition : Format.formatter -> type_definition -> unit

val show_type_definition : type_definition -> string

val pp_function_definition : Format.formatter -> function_definition -> unit

val show_function_definition : function_definition -> string

val pp_adt_definition : Format.formatter -> adt_definition -> unit

val show_adt_definition : adt_definition -> string

val pp_binding : Format.formatter -> binding -> unit

val show_binding : binding -> string

val pp_signature : Format.formatter -> signature -> unit

val show_signature : signature -> string

val pp_parameter : Format.formatter -> parameter -> unit

val show_parameter : parameter -> string

val pp_typing : Format.formatter -> typing -> unit

val show_typing : typing -> string

val pp_typing_constructor : Format.formatter -> typing_constructor -> unit

val show_typing_constructor : typing_constructor -> string

val pp_function_typing : Format.formatter -> function_typing -> unit

val show_function_typing : function_typing -> string

val pp_expression : Format.formatter -> expression -> unit

val show_expression : expression -> string

val pp_constructor : Format.formatter -> constructor -> unit

val show_constructor : constructor -> string

val pp_binary_operation : Format.formatter -> binary_operation -> unit

val show_binary_operation : binary_operation -> string

val pp_unary_operation : Format.formatter -> unary_operation -> unit

val show_unary_operation : unary_operation -> string

val pp_let_expr : Format.formatter -> let_expr -> unit

val show_let_expr : let_expr -> string

val pp_desugared_let_expr : Format.formatter -> desugared_let_expr -> unit

val show_desugared_let_expr : desugared_let_expr -> string

val pp_if_expr : Format.formatter -> if_expr -> unit

val show_if_expr : if_expr -> string

val pp_match_expr : Format.formatter -> match_expr -> unit

val show_match_expr : match_expr -> string

val pp_lambda_expr : Format.formatter -> lambda_expr -> unit

val show_lambda_expr : lambda_expr -> string

val pp_desugared_lambda_expr : Format.formatter -> desugared_lambda_expr -> unit

val show_desugared_lambda_expr : desugared_lambda_expr -> string

val pp_application : Format.formatter -> application -> unit

val show_application : application -> string

val pp_expression_with_signature :
  Format.formatter -> expression_with_signature -> unit

val show_expression_with_signature : expression_with_signature -> string

val pp_binary_operator : Format.formatter -> binary_operator -> unit

val show_binary_operator : binary_operator -> string

val pp_unary_operator : Format.formatter -> unary_operator -> unit

val show_unary_operator : unary_operator -> string

val pp_variant : Format.formatter -> variant -> unit

val show_variant : variant -> string

val pp_case : Format.formatter -> case -> unit

val show_case : case -> string

val pp_pattern : Format.formatter -> pattern -> unit

val show_pattern : pattern -> string

val pp_constructor_pattern : Format.formatter -> constructor_pattern -> unit

val show_constructor_pattern : constructor_pattern -> string

val pp_or_pattern : Format.formatter -> or_pattern -> unit

val show_or_pattern : or_pattern -> string
