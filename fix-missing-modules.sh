#!/bin/bash
# Usage: $ drop local.yml drush uli
# Runs drush in the build path
set -e

main() {
  # Check if modlue exists at the begining
  module_exists=$(get_module_path module_missing_message_fixer)
  $drush --root=$drop_docroot en module_missing_message_fixer -y
  $drush --root=$drop_docroot cc drush
  $drush --root=$drop_docroot mmmff --all

  if [[ -z $module_exists ]]; then
    $drush --root=$drop_docroot dis module_missing_message_fixer -y
    echo "Removing module_missing_message_fixer module."
    rm -r $(get_module_path module_missing_message_fixer)
  fi
}

get_module_path() {
  local module_name=$1
  echo $(find $drop_docroot -type d | grep $module_name$)
}

main
