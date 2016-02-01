#!/bin/bash
# Usage: $ drop local.yml drush uli
# Runs drush in the build path
set -e

echo "Running drush at "$config_build_path
drush --root=$config_build_path "$@"
