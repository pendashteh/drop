#!/bin/bash
# Usage: $ drop -- config
set -e

echo "Going to $drop_docroot"
echo "to exit type 'exit'"
cd $drop_docroot
init_file=$(mktemp -t XXXX)
echo 'PS1="drop> \$(pwd)$ "' > $init_file
exec bash --init-file $init_file
