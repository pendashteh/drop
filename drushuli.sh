#!/bin/bash
# Usage: $ drop local.yml drushuli
# Runs drush in the build path
set -e
$drush --root=$drop_docroot uli --browser=0 --uri=$config_drupal_url
