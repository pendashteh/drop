#!/bin/bash
# Usage: $ drop -- script scripts/menu-export.sh
set -e

custom_script_path="$1"
[ ! -e "$custom_script_path" ] && echo "No script found at "$custom_script_path && exit 1

. $custom_script_path

exit 0
