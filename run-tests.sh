#!/bin/bash
#
# Executes Drupal core run-tests.sh script localted at `scripts/run-tests.sh`
# Usage: $ drop -- run-tests [other arguments]
# 
set -e

[ "$BASH_ARGV" != "$BASH_SOURCE" ] && vars="${@}" || vars=""

php $drop_docroot/scripts/run-tests.sh $vars
