#!/bin/bash
# pass-diceware: an extension to zx2c4's "pass" to generate passwords using the diceware method
# Copyright (C) 2018 Giuseppe Stelluto
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

# This is essentially a modified version of the function cmd_generate() present in the "pass" source code
local opts qrcode=0 clip=0 force=0 characters="$CHARACTER_SET" inplace=0 pass
local dicefile="$EXTENSIONS/diceware.wordlist.asc" # default value
[[ -f $dicefile ]] || dicefile="$SYSTEM_EXTENSION_DIR/diceware.wordlist.asc" # if there is no user file, use system one (if it does not exist it will raise error later)
opts="$($GETOPT -o nqcif -l no-symbols,qrcode,clip,in-place,diceware-file:,force -n "$PROGRAM" -- "$@")"
local err=$?
eval set -- "$opts"
while true; do case $1 in
                   -n|--no-symbols) characters="$CHARACTER_SET_NO_SYMBOLS"; shift ;;
                   -q|--qrcode) qrcode=1; shift ;;
                   -c|--clip) clip=1; shift ;;
                   -f|--force) force=1; shift ;;
                   -i|--in-place) inplace=1; shift ;;
                   --diceware-file) shift; dicefile=$1; shift ;;
                   --) shift; break ;;
               esac done
[[ $err -ne 0 || ( $# -ne 2 && $# -ne 1 ) || ( $force -eq 1 && $inplace -eq 1 ) || ( $qrcode -eq 1 && $clip -eq 1 ) ]] && die "Usage: $PROGRAM $COMMAND [--diceware-file=file,-d file] [--no-symbols,-n] [--clip,-c] [--qrcode,-q] [--in-place,-i | --force,-f] pass-name [pass-phrase-length]"
[[ -f "$dicefile" ]] || die "Couldn't find a diceware file at \"$dicefile\" Try specifying a valid one with --diceware-file FILE"
local path="$1"
local length="${2:-$GENERATED_LENGTH}"
check_sneaky_paths "$path"
[[ $length =~ ^[0-9]+$ ]] || die "Error: pass-hrase-length \"$length\" must be a number."
[[ $length -gt 0 ]] || die "Error: pass-phrase-length must be greater than zero."
mkdir -p -v "$PREFIX/$(dirname -- "$path")"
set_gpg_recipients "$(dirname -- "$path")"
local passfile="$PREFIX/$path.gpg"
set_git "$passfile"

[[ $inplace -eq 0 && $force -eq 0 && -e $passfile ]] && yesno "An entry already exists for $path. Overwrite it?"


# The provided diceware file *should* be checked with gpg
# However, as of 2018-08-14 and GnuPG version 2.2.9, the official diceware file from "http://world.std.com/%7Ereinhold/diceware.wordlist.asc" can not be verified
# gpg fails with signature digest conflict in message
# There should be a line after BEGIN-PGP-SIGNED-MESSAGE specifying the hash algo used, but it is missing
# TODO: When the issue is solved, uncomment the lines below
# VERIFY="$(gpg --verify $WORDLIST_DIR)"
# [[ "$?" -eq 0 ]] || die "The file $WORDLIST_DIR has an invalid GPG signature."


local pass="$(cat $dicefile | tail -n +3 | head -n -11 | shuf -n $length $WORDLIST_DIR | awk '{ print $2 }' |  tr '\n' ' ' | head -c -1)"
[[ "$(echo "$pass" | wc -w)" -eq $length ]] || die "Could not generate password from diceware.wordlist"
if [[ $inplace -eq 0 ]]; then
    $GPG -e "${GPG_RECIPIENT_ARGS[@]}" -o "$passfile" "${GPG_OPTS[@]}" <<<"$pass" || die "Password encryption aborted."
else
    local passfile_temp="${passfile}.tmp.${RANDOM}.${RANDOM}.${RANDOM}.${RANDOM}.--"
    if { echo "$pass"; $GPG -d "${GPG_OPTS[@]}" "$passfile" | tail -n +2; } | $GPG -e "${GPG_RECIPIENT_ARGS[@]}" -o "$passfile_temp" "${GPG_OPTS[@]}"; then
        mv "$passfile_temp" "$passfile"
    else
        rm -f "$passfile_temp"
        die "Could not reencrypt new password."
    fi
fi
local verb="Add"
[[ $inplace -eq 1 ]] && verb="Replace"
git_add_file "$passfile" "$verb generated password for ${path}."

if [[ $clip -eq 1 ]]; then
    clip "$pass" "$path"
elif [[ $qrcode -eq 1 ]]; then
    qrcode "$pass" "$path"
else
    printf "\e[1m\e[37mThe generated password for \e[4m%s\e[24m is:\e[0m\n\e[1m\e[93m%s\e[0m\n" "$path" "$pass"
fi
exit $?
