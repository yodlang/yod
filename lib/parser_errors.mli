(*
 * SPDX-FileCopyrightText: 2025 Milesime <213074881+milesime@users.noreply.github.com>
 *
 * SPDX-License-Identifier: GPL-2.0-only
 *)

val message : int -> string
(** Retrieves the error message corresponding to a parser error code. These
    messages are auto-generated from the parser.messages file and provide
    user-friendly explanations of syntax errors during parsing.

    @param s The error code to look up.
    @return A human-readable error message explaining the syntax error.
    @raise Not_found If no message is defined for the given error code. *)
