#!/bin/bash
# Usage: drop -- rebuild
set -e

db_command() {
  local __db_url="" && [ ! -z "1" ] && __db_url=$1
  local __no_db=false && [ ! -z "$2" ] && __no_db=$2

  mysql_command=$($drush --root=$drop_docroot sql-connect --db-url=$__db_url)
  if [ "$__no_db" == true ]; then
    mysql_command=$(echo $mysql_command | sed 's/--database=[^-]*//g')
  fi
  echo $mysql_command
}
