(*
 * SPDX-FileCopyrightText: 2025 Milesime <213074881+milesime@users.noreply.github.com>
 *
 * SPDX-License-Identifier: GPL-3.0-only
 *)

open Yod

let lexbuf_from_file file =
  let buf = Sedlexing.Utf8.from_channel @@ open_in_bin file in
  Sedlexing.set_filename buf file ;
  buf

let lexbuf_from_stdin () = Sedlexing.Utf8.from_channel stdin

let flush_string s = print_string s ; flush stdout

let write_file file = Printf.fprintf (open_out_bin file) "%s%!"

let report_and_exit ?(json = false) kind code msg span =
  Reporter.print_reports ~json [Reporter.create_report kind code msg span] ;
  exit code

(* Error handling wraps lexer/parser errors with specific error codes to enable
   structured output for tooling integration and clear user feedback. *)
let parse ?(json = false) buf =
  try Parser.parse buf with
  | Lexer.Lexing_error span ->
      report_and_exit ~json Reporter.Error 1 "Unexpected character." span
  | Parser.Syntax_error (code, msg, span) ->
      report_and_exit ~json Reporter.Error (code + 2) msg span

(* Program analysis is separated from parsing to allow for independent
   verification of different compiler stages, errors bubble up with clear
   context rather than cascading through the pipeline. *)
let analyze ?(json = false) program =
  try Usage_analysis.analyze_program ~json program
  with Usage_analysis.Output.Analysis_error reports ->
    Reporter.print_reports ~json reports ;
    exit (if json then 0 else 1000)

let transpile_pipeline lexbuf =
  parse lexbuf |> Desugar.desugar_program |> analyze |> Transpiler.build_program

(* Transpiling to file adds extension rather than replacing to preserve source
   files and make the relationship between input/output clear. *)
let transpile_file file =
  lexbuf_from_file file |> transpile_pipeline |> write_file (file ^ ".ml")

(* Processing stdin provides UNIX-like pipeline integration for tooling
   workflows. *)
let transpile_stdin () =
  lexbuf_from_stdin () |> transpile_pipeline |> flush_string

let format_pipeline lexbuf = parse lexbuf |> Formatter.format

let format_file file =
  lexbuf_from_file file |> format_pipeline |> write_file file

let format_stdin () = lexbuf_from_stdin () |> format_pipeline |> flush_string

(* Debug function combines parsing, formatting and analysis for integration with
   tooling like our VS Code extension. *)
let fmt_debug () =
  let ast = lexbuf_from_stdin () |> parse ~json:true in
  ast |> Formatter.format |> flush_string ;
  ast |> Desugar.desugar_program |> analyze ~json:true |> ignore

let parse_pipeline lexbuf =
  parse lexbuf |> Desugar.desugar_program |> analyze |> Ast.show_program

let parse_file file = lexbuf_from_file file |> parse_pipeline |> print_endline

let parse_stdin () = lexbuf_from_stdin () |> parse_pipeline |> print_endline

(* Usage information formatted as a table improves readability and helps users
   understand the command structure at a glance. *)
let print_usage () =
  print_endline
    {|╭──────────────────────────┬───────────────────────────────────────────────────╮
│ Command                  │ Description                                       │
├──────────────────────────┼───────────────────────────────────────────────────┤
│ yod                      │ Parse standard input and display the AST.         │
├──────────────────────────┼───────────────────────────────────────────────────┤
│ yod <file.yod>           │ Parse a file and display the AST.                 │
├──────────────────────────┼───────────────────────────────────────────────────┤
│ yod fmt                  │ Format standard input and output it.              │
├──────────────────────────┼───────────────────────────────────────────────────┤
│ yod fmt <file.yod>       │ Format a file and overwrite it.                   │
├──────────────────────────┼───────────────────────────────────────────────────┤
│ yod transpile            │ Transpile standard input and output it.           │
├──────────────────────────┼───────────────────────────────────────────────────┤
│ yod transpile <file.yod> │ Transpile a file and write its OCaml counterpart. │
╰──────────────────────────┴───────────────────────────────────────────────────╯|} ;
  exit 1

let validate_file file =
  if not (String.ends_with ~suffix:".yod" file) then print_usage ()

(* Command handling uses pattern matching rather than complex parsing logic to
   keep the interface simple and maintainable while being easily extensible. *)
let () =
  match Sys.argv with
  | [|_; "transpile"; file|] ->
      validate_file file ; transpile_file file
  | [|_; "transpile"|] ->
      transpile_stdin ()
  | [|_; "fmt"; file|] ->
      validate_file file ; format_file file
  | [|_; "fmt"|] ->
      format_stdin ()
  | [|_; "fmt-debug"|] ->
      fmt_debug ()
  | [|_; file|] ->
      validate_file file ; parse_file file
  | [|_|] ->
      parse_stdin ()
  | _ ->
      print_usage ()
