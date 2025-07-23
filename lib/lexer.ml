(*
 * SPDX-FileCopyrightText: 2025 Milesime <213074881+milesime@users.noreply.github.com>
 *
 * SPDX-License-Identifier: GPL-2.0-only
 *)

open Sedlexing.Utf8
open Menhir_parser

exception Lexing_error of (Lexing.position * Lexing.position)

(* Regular expressions are defined using sedlex to support Unicode characters,
   making the language more accessible internationally. *)
let newline = [%sedlex.regexp? "\r\n" | '\n']

let digit = [%sedlex.regexp? '0' .. '9']

let exp = [%sedlex.regexp? 'e' | 'E', Opt ('+' | '-'), Plus digit]

let integer = [%sedlex.regexp? Plus digit, Opt exp]

let floating = [%sedlex.regexp? Plus digit, '.', Plus digit, Opt exp]

let alnum = [%sedlex.regexp? lowercase | uppercase | digit | '_']

(* We distinguish between uppercase and lowercase identifiers to simplify
   parsing of types, constructors and variables. *)
let uid = [%sedlex.regexp? uppercase, Star alnum, Star '\'']

let lid = [%sedlex.regexp? (lowercase | '_'), Star alnum, Star '\'']

(* String lexing uses a special recursive function to handle escape sequences
   and multi-character strings efficiently. *)
let string buf =
  let buffer = Buffer.create 16 in
  let rec aux buf =
    match%sedlex buf with
    | {|\"|} ->
        Buffer.add_char buffer '"' ; aux buf
    | Compl '"' ->
        Buffer.add_string buffer (lexeme buf) ;
        aux buf
    | '"' ->
        STRING (Buffer.contents buffer)
    | _ ->
        assert false
  in
  aux buf

let comment buf =
  let buffer = Buffer.create 64 in
  let rec aux buf =
    match%sedlex buf with
    | newline, Compl '#' | eof ->
        Sedlexing.rollback buf ;
        COMMENT (String.trim @@ Buffer.contents buffer)
    | any ->
        Buffer.add_string buffer (lexeme buf) ;
        aux buf
    | _ ->
        assert false
  in
  aux buf

(* The main tokenizer function uses a pattern matching approach to recognize
   language constructs, prioritizing longer matches over shorter ones. *)
let rec tokenizer buf =
  match%sedlex buf with
  | white_space ->
      tokenizer buf
  | "def" ->
      KWDEF
  | "let" ->
      KWLET
  | "in" ->
      KWIN
  | "if" ->
      KWIF
  | "then" ->
      KWTHEN
  | "else" ->
      KWELSE
  | "Int" ->
      KWINT
  | "Float" ->
      KWFLOAT
  | "Bool" ->
      KWBOOL
  | "String" ->
      KWSTRING
  | "Unit" ->
      KWUNIT
  | "match" ->
      KWMATCH
  | "as" ->
      KWAS
  | '=' ->
      EQUAL
  | ":=" ->
      COLONEQUAL
  | ':' ->
      COLON
  | '{' ->
      LBRACE
  | '}' ->
      RBRACE
  | '(' ->
      LPAREN
  | ')' ->
      RPAREN
  | '[' ->
      LBRACKET
  | ']' ->
      RBRACKET
  | ',' ->
      COMMA
  | "->" ->
      ARROW
  | ';' ->
      SEMICOLON
  | "()" ->
      UNIT
  | '\\' ->
      BACKSLASH
  | "..." ->
      ELLIPSIS
  | "|>" ->
      TRIANGLE
  | "||" ->
      BARBAR
  | "&&" ->
      ANDAND
  | "==" ->
      EQUALEQUAL
  | "!=" ->
      BANGEQUAL
  | '>' ->
      GT
  | ">=" ->
      GEQ
  | '<' ->
      LT
  | "<=" ->
      LEQ
  | "++" ->
      PLUSPLUS
  | '+' ->
      PLUS
  | '-' ->
      MINUS
  | '*' ->
      STAR
  | '/' ->
      SLASH
  | '%' ->
      PERCENT
  | "**" ->
      STARSTAR
  | '!' ->
      BANG
  | '#' ->
      comment buf
  | integer ->
      INT (lexeme buf)
  | floating ->
      FLOAT (lexeme buf)
  | "True" ->
      BOOL true
  | "False" ->
      BOOL false
  | '"' ->
      string buf
  | uid ->
      UID (lexeme buf)
  | lid ->
      LID (lexeme buf)
  | eof ->
      EOF
  | _ ->
      raise @@ Lexing_error (Sedlexing.lexing_positions buf)

(* The lexer wrapper simplifies interaction with the tokenizer by handling the
   token stream and position tracking. *)
let lexer buf = Sedlexing.with_tokenizer tokenizer buf
