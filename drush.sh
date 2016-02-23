#!/bin/bash
# Usage: $ drop local.yml drush uli
# Runs drush in the build path
set -e

echo "Running drush at "$drop_docroot
drush --root=$drop_docroot "$@"
