#!/bin/bash
# Usage: $ drop -- config
set -e

echo "Going to $drop_docroot"
echo "to exit type 'exit'"
cd $drop_docroot
export PS1="drop> \$(pwd)$ "
exec bash