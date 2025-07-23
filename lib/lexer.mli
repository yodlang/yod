(*
 * SPDX-FileCopyrightText: 2025 Milesime <213074881+milesime@users.noreply.github.com>
 *
 * SPDX-License-Identifier: GPL-2.0-only
 *)

(** Exception raised when a lexing error is encountered during tokenization.
    Contains the positions where the error occurred in the source text.

    @param loc The start and end position of the lexical error. *)
exception Lexing_error of (Lexing.position * Lexing.position)

val lexer :
     Sedlexing.lexbuf
  -> unit
  -> Menhir_parser.token * Lexing.position * Lexing.position
(** Creates a lexer function for tokenizing Yod source code. This lexer converts
    the input text into a stream of tokens for the parser. It handles keywords,
    operators, literals, identifiers, and comments.

    @param buf The UTF-8 buffer containing the source text to tokenize.
    @return A function that produces tokens along with their source positions.
    @raise Lexing_error When an invalid token is encountered. *)
