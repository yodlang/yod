# SPDX-FileCopyrightText: 2025 Milesime <213074881+milesime@users.noreply.github.com>
#
# SPDX-License-Identifier: GPL-3.0-only

list-errors:
    menhir lib/menhir_parser.mly --table --list-errors > lib/parser.messages

compile-errors:
    menhir lib/menhir_parser.mly --table --compile-errors lib/parser.messages > lib/parser_errors.ml
