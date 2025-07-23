(*
 * SPDX-FileCopyrightText: 2025 Milesime <213074881+milesime@users.noreply.github.com>
 *
 * SPDX-License-Identifier: GPL-2.0-only
 *)

open Lexing
open Printf

let reset = "\027[0m"

(* ANSI color codes are used to provide visual differentiation between different
   types of compiler messages, improving readability. *)
let colorize color txt = color ^ txt ^ reset

let underline = colorize "\027[4m"

let black = colorize "\027[30m"

let red = colorize "\027[31m"

let orange = colorize "\027[33m"

let blue = colorize "\027[34m"

let purple = colorize "\027[35m"

let white = colorize "\027[37m"

let bright_black = colorize "\027[90m"

type severity = Info | Warning | Error

(* Single character codes are used for severity to keep the output compact while
   still being informative. *)
let string_of_severity = function Info -> "I" | Warning -> "W" | Error -> "E"

let color_of_severity = function
  | Info ->
      blue
  | Warning ->
      orange
  | Error ->
      red

let rec space n = if n <= 0 then "" else " " ^ space (n - 1)

let column pos = pos.pos_cnum - pos.pos_bol

type report =
  { severity: severity
  ; code: int
  ; msg: string
  ; range: position * position
  ; hint: string
  ; note: string }

(* JSON output format enables integration with external tools and IDEs that can
   parse and display errors in their own UI. *)
let print_json_reports reports =
  let json_reports =
    List.map
      (fun {severity; code; msg; range; _} ->
        let start, fin = range in
        `Assoc
          [ ("code", `String (string_of_severity severity ^ sprintf "%04d" code))
          ; ("msg", `String msg)
          ; ("startLine", `Int (start.pos_lnum - 1))
          ; ("startCol", `Int (column start))
          ; ("endLine", `Int (fin.pos_lnum - 1))
          ; ("endCol", `Int (column fin)) ] )
      reports
  in
  Yojson.Safe.to_channel stderr (`List json_reports) ;
  flush stderr

(* Unicode box-drawing characters are used to create visually appealing and
   clear error reporting with connecting lines between related parts. *)
let print_header range severity code msg margin file_name =
  let start, fin = range in
  let arc_down_right = "\u{256D}" in
  let horizontal = "\u{2574}" in
  let vertical_right = "\u{251C}" in
  let line_pos =
    if start.pos_lnum = fin.pos_lnum then string_of_int start.pos_lnum
    else string_of_int start.pos_lnum ^ "-" ^ string_of_int fin.pos_lnum
  in
  eprintf "%s%s\n"
    (color_of_severity severity
       (string_of_severity severity ^ sprintf "%04d" code) )
    (white (": " ^ msg)) ;
  eprintf "%s %s%s:%s:%d-%d\n"
    (space (if file_name = "" then 0 else margin))
    ( black
    @@ (if file_name = "" then vertical_right else arc_down_right)
    ^ horizontal )
    (if file_name = "" then "stdin" else Filename.basename file_name)
    line_pos
    (column start + 1)
    (column fin + 1)

(* Each line of code containing errors is printed with line numbers and
   highlighting to precisely point to the problematic region. *)
let print_line hint note range margin n line =
  let start, fin = range in
  let n_str = string_of_int n in
  let margin_space = space (margin - String.length n_str) in
  let vertical = "\u{2502}" in
  let up = "\u{2575}" in
  let line_prefix =
    sprintf "%s%s %s " margin_space (bright_black n_str) (black vertical)
  in
  if n = start.pos_lnum - 1 then (
    if line <> "" then eprintf "%s %s\n" (space margin) (black vertical) ;
    eprintf "%s%s\n" line_prefix line )
  else if n >= start.pos_lnum && n <= fin.pos_lnum then
    let error_range =
      if n = start.pos_lnum && n = fin.pos_lnum then
        (column start, column fin - column start)
      else if n = start.pos_lnum then
        (column start, String.length line - column start)
      else if n = fin.pos_lnum then (0, column fin)
      else (0, String.length line)
    in
    eprintf "%s%s%s%s\n" line_prefix
      (String.sub line 0 (fst error_range))
      (underline (red (String.sub line (fst error_range) (snd error_range))))
      (String.sub line
         (fst error_range + snd error_range)
         (String.length line - (fst error_range + snd error_range)) )
  else if n = fin.pos_lnum + 1 then
    eprintf "%s%s\n%s %s\n%!" line_prefix line (space margin)
      (black (if hint <> "" || note <> "" then vertical else up))

(* Additional hints and notes are provided to suggest fixes and explain the
   error in more detail, making the compiler more educational. *)
let print_footer hint note margin file_name =
  let vertical_right = "\u{251C}" in
  let up = "\u{2575}" in
  if hint <> "" then
    eprintf "%s %s %s: %s\n"
      (space (if file_name = "" then 0 else margin))
      (black vertical_right) (purple "Hint") hint ;
  if note <> "" then
    eprintf "%s %s %s: %s\n"
      (space (if file_name = "" then 0 else margin))
      (black vertical_right) (blue "Note") note ;
  if hint <> "" || note <> "" || file_name = "" then
    eprintf "%s %s\n%!"
      (space (if file_name = "" then 0 else margin))
      (black up)

let print_report {severity; code; msg; range; hint; note} =
  let msg = String.trim msg in
  let hint = String.trim hint in
  let note = String.trim note in
  let start, fin = range in
  (* Calculate margin based on the max line number to ensure consistent
     alignment throughout the error message. *)
  let margin = String.length (string_of_int (fin.pos_lnum + 1)) in
  let file_name = start.pos_fname in
  print_header range severity code msg margin file_name ;
  if file_name <> "" then (
    let file = open_in_bin file_name in
    for n = 1 to fin.pos_lnum + 1 do
      Option.iter
        (print_line hint note range margin n)
        (In_channel.input_line file)
    done ;
    close_in file ) ;
  print_footer hint note margin file_name

let create_report ?(hint = "") ?(note = "") severity code msg range =
  {severity; code; msg; range; hint; note}

let print_reports ?(json = false) reports =
  if json then print_json_reports reports
  else List.iter (fun report -> print_report report) reports
