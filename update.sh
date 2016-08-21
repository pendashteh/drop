#!/bin/bash
# Usage: $ drop -- update [-y]
set -e

[[ $1 = "-y" ]] && force_yes="-y"

main() {

	debug drush --root=$drop_docroot updb $force_yes

	debug drush --root=$drop_docroot cc all

	if [ "$config_install_rebuild_permissions" = "true" ]
		then
		debug drush --root=$drop_docroot ev 'node_access_rebuild();'
	fi

	if [ "$config_install_features_revert_all" = "true" ]
		then
		debug drush --root=$drop_docroot fra $force_yes
	fi

	if [ "$config_install_print_uli" = "true" ]
		then
		drush --root=$drop_docroot uli --browser=0 --uri=$config_drupal_url
	fi

	echo "Finished successfully."
}

main
