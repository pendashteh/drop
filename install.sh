#!/bin/bash
# Usage: $ drop -- install.sh [-y]
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

main() {

	_check_database_connection

	_generate_settings_php $config_install_db_url

	if [[ -e $config_install_db_dump ]]
		then
		echo "Re-installing "$config_profile_name" on top of DB dump."
		_import_db $config_install_db_dump
		enable_profile $config_profile_name

	else

		if [ ! "$config_install_base_profile" ] || [ "$config_install_base_profile" = "$config_profile_name" ]
			then
			_install_profile $config_profile_name
		else
			_install_profile $config_install_base_profile
			enable_profile $config_profile_name
		fi
	fi


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

	if [ -s "$config_install_post_script" ]
		then
		_exec_script $config_install_post_script;
	fi
}

_check_database_connection() {
	# @FIXME this method will not detect wrong port and will pass anyways.
	mysql_command=$(drush --root=$config_build_path sql-connect --db-url=$config_install_db_url)
	error="$($mysql_command -e ';')"
}

enable_profile() {
	drush --root=$config_build_path vset --exact -y install_profile $1
	drush --root=$config_build_path en $1 $force_yes
}

_generate_settings_php() {
	local __db_url=$1

	drush --root=$config_build_path dl settingsphp -y
	drush --root=$config_build_path cc drush -y
	drush --root=$config_build_path settingsphp-generate --db-url=$__db_url $force_yes
}

_install_profile() {
	local __profile=$1
	drush --root=$config_build_path si $force_yes
}

_import_db() {
	local __db_dump=$1
	drush --root=$config_build_path sql-cli < $__db_dump
	echo "Rebuilding registry..."
	php $script_root/scripts/rr.php --root=$config_build_path 1>/dev/null
}

main
