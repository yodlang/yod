(*
 * SPDX-FileCopyrightText: 2025 Milesime <213074881+milesime@users.noreply.github.com>
 *
 * SPDX-License-Identifier: GPL-3.0-only
 *)

(** Exception raised when a syntax error is encountered during parsing. Contains
    the error code, error message, and source positions.

    @param int The error code that identifies the specific syntax error.
    @param string The human-readable description of the syntax error.
    @param loc The start and end position where the syntax error was detected.
*)
exception Syntax_error of int * string * (Lexing.position * Lexing.position)

val parse : Sedlexing.lexbuf -> Ast.program
(** Parses a Yod source file into an AST representation. Uses incremental
    parsing with Menhir and handles error reporting.

    @param lexbuf The lexing buffer containing the source code to parse.
    @return An [Ast.program] representing the parsed program.
    @raise Syntax_error When a syntax error is encountered. *)
