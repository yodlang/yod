(*
 * SPDX-FileCopyrightText: 2025 Milesime <213074881+milesime@users.noreply.github.com>
 *
 * SPDX-License-Identifier: GPL-3.0-only
 *)

val build_program : Yod.Ast.program -> string
(** Translates a Yod AST into OCaml source code.

    This function transpiles Yod language constructs directly to their OCaml
    equivalents. It handles type definitions, value bindings, pattern matching,
    algebraic data types, and all expressions supported by the Yod language.

    The AST must be desugared before transpiling. This function expects complex
    constructs like function definitions and let expressions to be transformed
    into their simpler forms (value bindings with lambdas and desugared lets).
    The transpiler will fail with an error message if it encounters
    non-desugared nodes.

    Built-in functions and operators are mapped to their OCaml counterparts
    (e.g., “printString” becomes “print_endline”, “π” becomes “Float.pi”).

    @param program The desugared AST representing a Yod program.
    @return OCaml source code as a string ready for compilation.
    @raise Failure
      When encountering non-desugared constructs like function definitions or
      standard let expressions. *)
