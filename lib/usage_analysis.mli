(*
 * SPDX-FileCopyrightText: 2025 Milesime <213074881+milesime@users.noreply.github.com>
 *
 * SPDX-License-Identifier: GPL-2.0-only
 *)

(** Module for interfacing with the output of the usage analysis. *)
module Output : sig
  (** Exception raised when analysis detects errors in the program.

      @param reports
        A list of diagnostic reports describing the analysis errors. *)
  exception Analysis_error of Reporter.report list
end

val analyze_program : ?json:bool -> Ast.declaration list -> Ast.declaration list
(** Analyzes the AST for issues related to variable, type and variant usage.

    This function performs various static analyses on the program, including:
    - Warning about unused identifiers
    - Checking for references to undefined identifiers
    - Checking for name clash with reserved or duplicate identifiers
    - Checking for constructor mismatch of variants

    The AST must be desugared before analysis. This function expects complex
    constructs like function definitions and let expressions to be transformed
    into their simpler forms (value bindings with lambdas and desugared lets).
    The analysis will fail with an error message if it encounters non-desugared
    nodes.

    @param json
      When set to [true], outputs any analysis warnings in JSON format instead
      of the default human-readable format. Defaults to [false].
    @param program The desugared AST of the program to analyze.
    @return The same AST if no fatal errors are found.
    @raise Output.Analysis_error
      When analysis detects errors that prevent compilation from proceeding. *)
