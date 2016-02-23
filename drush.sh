#!/bin/bash
# Usage: $ drop local.yml drush uli
# Runs drush in the build path
set -e

drush --root=$drop_docroot "$@"
