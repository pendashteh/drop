##!/usr/bin/env bash

# Usage: $ drop local.yml db-sql --no-db "show databases;"
set -e

local __sql=${@}
local __no_db=false && [ "$1" == "--no-db" ] && __no_db=true && __sql=${@:2}

_db_command=$(db_command "" $__no_db)

echo $__sql | $_db_command
