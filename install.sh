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

	# Needs to be moved when 'defaults' feature has been implemented
	config_defaults_profile_name="standard"

	if [ "$config_profile_name" ]
		then
		_validate_profile
	fi

	_check_database_connection $config_drupal_db_url

	_generate_settings_php $config_drupal_db_url

	if [ "$config_install_db_dump" ]
		then
		if [[ ! -e $config_install_db_dump ]]
			then
			echo "DB dump could not be found at $config_install_db_dump"
			exit 1
		fi
		_import_db $config_install_db_dump
		if [ "$config_profile_name" ]
			then
			echo "Re-installing "$config_profile_name" on top of DB dump."
			enable_profile $config_profile_name
		fi
	else
		if [ ! "$config_profile_name" ]
			then
			echo "Installing default profile ($config_defaults_profile_name)"
			_install_profile $config_defaults_profile_name
		elif [ ! "$config_install_base_profile" ] || [ "$config_install_base_profile" = "$config_profile_name" ]
			then
			echo "Installing $config_profile_name profile"
			_install_profile $config_profile_name
		else
			echo "Installing $config_profile_name on top of $config_install_base_profile"
			_install_profile $config_install_base_profile
			enable_profile $config_profile_name
		fi
	fi


	drush --root=$drop_docroot updb $force_yes

	drush --root=$drop_docroot cc all

	if [ "$config_install_features_revert_all" = "true" ]
		then
		drush --root=$drop_docroot fra $force_yes
	fi

	if [ -s "$config_install_post_script" ]
		then
		_exec_script $config_install_post_script;
	fi

	if [ "$config_deploy_install_print_uli" = "true" ]
		then
		drush --root=$drop_docroot uli --browser=0 --uri=$config_drupal_url
	fi

	echo "Finished successfully."
	exit 0
}

_check_database_connection() {
	local __db_url=$1
	# @FIXME this method will not detect wrong port and will pass anyways.
	mysql_command=$(drush --root=$drop_docroot sql-connect --db-url=$__db_url)
	error="$($mysql_command -e ';')"
}

enable_profile() {
	drush --root=$drop_docroot vset --exact -y install_profile $1
	drush --root=$drop_docroot en $1 $force_yes
}

_generate_settings_php() {
	if [ ! "$config_install_settingsphp_generate" = "true" ]
		then
		return
	fi

	local __db_url=$1

	_default_settingsphp_name="settings.php"
	sites_default_path=$drop_docroot/sites/default
	if [ ! "$config_install_settingsphp_filename" ]
		then
		config_install_settingsphp_filename=$_default_settingsphp_name
	fi

	chmod -R u+w $sites_default_path

	local _preserve_original_settingsphp
	if [ "$config_install_settingsphp_filename" ] && [ "$config_install_settingsphp_filename" != "$_default_settingsphp_name" ]
		then
		if [ ! -e $sites_default_path/$_default_settingsphp_name ]
			then
			echo "No settings.php found or configured to be generated."
			exit 1
		fi
		_preserve_original_settingsphp="true"
	fi

	if [ "$_preserve_original_settingsphp" = "true" ]
		then
		mv $sites_default_path/settings.php $sites_default_path/original.settings.php
	fi

	drush --root=$drop_docroot dl settingsphp -y
	drush --root=$drop_docroot cc drush -y
	debug drush --root=$drop_docroot settingsphp-generate --db-url=$__db_url --db-prefix="kids_drupal_" $force_yes

	if [ "$_preserve_original_settingsphp" = "true" ]
		then
		mv $sites_default_path/settings.php $sites_default_path/$config_install_settingsphp_filename
		mv $sites_default_path/original.settings.php $sites_default_path/settings.php
	fi

}

_install_profile() {
	local __profile=$1
	drush --root=$drop_docroot si $__profile $force_yes
}

_import_db() {
	local __db_dump=$1
	echo "making sure the current database is empty"
	drush --root=$drop_docroot sql-drop $force_yes
	debug drush --root=$drop_docroot sql-cli < $__db_dump
	echo "Rebuilding registry..."
	php $script_root/scripts/rr.php --root=$drop_docroot 1>/dev/null
}

main
