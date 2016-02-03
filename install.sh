#!/bin/bash
# Usage: ./install.sh [-y]
set -e

[[ $1 = "-y" ]] && force_yes="-y"

# Three cases:
# 1. We install a fresh 'profile':
#	si profile
# 2. We install 'profile' on top of a 'base' profile
#	si base; en profile
# 3. We install 'profile' on top of 'db dump'
#	si minimal; sqlc; rr; en profile
# 4. We just import 'db dump'
#	si minimal; sqlc; rr;

enable_profile() {
	drush --root=$config_build_path vset --exact -y install_profile $1
	drush --root=$config_build_path en $1 $force_yes
}

echo "Installation of "$config_profile_name" on top of "$config_install_base_profile

drush --root=$config_build_path si $config_install_base_profile --db-url=$config_install_db_url $force_yes

if [[ -e $config_install_db_dump ]]
	then
	echo "Re-installing "$config_profile_name" on top of DB dump."

	drush --root=$config_build_path si minimal --db-url=$config_install_db_url $force_yes
	drush --root=$config_build_path sql-cli < $config_install_db_dump

	echo "Rebuilding registry..."
	php $script_root/scripts/rr.php --root=$config_build_path 1>/dev/null
fi

enable_profile $config_profile_name

drush --root=$config_build_path updb $force_yes

drush --root=$config_build_path cc all

if [ "$config_install_features_revert_all" = "true" ]
	then
	drush --root=$config_build_path fra $force_yes
fi

if [ "$config_install_print_uli" = "true" ]
	then
	drush --root=$config_build_path uli --browser=0
fi

if [ -e "$config_install_post_script" ]
	then
	_exec_script $config_install_post_script;
fi
