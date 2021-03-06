#!/bin/bash
# Usage: $ drop -- install [--ask]
set -e

# Force 'yes' on Drush commands for non-interactive commands
force_yes="-y"

# User can choose to be asked for confirmations by Drush
[[ $1 = "--ask" ]] && force_yes=""

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

	# @FIXME validate profile if provided

	_check_database_connection $config_drupal_db_url $config_install_db_create

	_generate_settings_php $config_drupal_db_url

	if [ "$config_install_db_dump" ]
		then
		if [[ ! -e $config_install_db_dump ]]
			then
			drop_info "DB dump could not be found at $config_install_db_dump"
			exit 1
		fi
		_import_db $config_install_db_dump
		if [ "$config_profile_name" ]
			then
			drop_info "Re-installing "$config_profile_name" on top of DB dump."
			enable_profile $config_profile_name
		fi
	else
		if [ ! "$config_profile_name" ]
			then
			drop_info "Installing default profile ($config_defaults_profile_name)"
			_install_profile $config_defaults_profile_name
		elif [ ! "$config_profile_base" ] || [ "$config_profile_base" = "$config_profile_name" ]
			then
			drop_info "Installing $config_profile_name profile"
			_install_profile $config_profile_name
		else
			drop_info "Installing $config_profile_name on top of $config_profile_base"
			_install_profile $config_profile_base
			enable_profile $config_profile_name
		fi
	fi

	drop_info "Install the theme if specified"
	_install_theme

	drop_info "Enable modules if any specified"
	_enable_modules

	drop_info "Disable modules if any specified"
	_disable_modules

	drop_info "Running the post install script, if provided"
	_post_install_script

	drop_info "Running update process..."
	drop_run_task update $force_yes

	drop_info "Creating a one-time login..."
	drop_run_task drushuli

	drop_info "Finished successfully."
}

_install_theme() {
	if  [ "$config_install_theme" ]; then
		debug $drush --root=$drop_docroot en $config_install_theme $force_yes
		debug $drush --root=$drop_docroot vset theme_default $config_install_theme $force_yes
	fi
}

_enable_modules() {
	if  [ "$config_install_enable_modules" ]; then
		debug $drush --root=$drop_docroot en $config_install_enable_modules $force_yes
	fi
}

_disable_modules() {
	if  [ "$config_install_disable_modules" ]; then
		debug $drush --root=$drop_docroot dis $config_install_disable_modules $force_yes
	fi
}

_post_install_script() {
	if  [ "$config_install_post_script" ]; then
		cd $drop_docroot
		. $config_install_post_script
	fi
}

_check_database_connection() {
	local __db_url=$1
	local __create_db=false && [ ! -z "$2" ] && __create_db=$2

	if [ "$__create_db" == false ]; then
		_db_command=$(db_command $__db_url)
		echo ";" | $_db_command
	else
		_db_command=$(db_command $__db_url true)
		_db_name=$(basename $__db_url)
		drop_info "Looking for the database $_db_name"
		_db_exists=false && echo "show databases;" | $_db_command | grep -w $_db_name && _db_exists=true
		if [ "$_db_exists" == "false" ]; then
			drop_info "Creating database $_db_name"
			echo "CREATE DATABASE $_db_name;" | $_db_command
		fi
	fi
}

enable_profile() {
	debug $drush --root=$drop_docroot vset --exact -y install_profile $1
	debug $drush --root=$drop_docroot en $1 $force_yes
}

_generate_settings_php() {
	if [ ! "$config_install_settingsphp_generate" = "true" ]
		then
		drop_info "Using the existing settings.php."
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
			drop_error "No settings.php found or configured to be generated."
			exit 1
		fi
		_preserve_original_settingsphp="true"
	fi

	if [ "$_preserve_original_settingsphp" = "true" ]
		then
		mv $sites_default_path/settings.php $sites_default_path/original.settings.php
	fi

	_install_settingsphp_check
	debug $drush --root=$drop_docroot settingsphp-generate --db-url=$__db_url --db-prefix="kids_drupal_" $force_yes

	if [ "$_preserve_original_settingsphp" = "true" ]
		then
		mv $sites_default_path/settings.php $sites_default_path/$config_install_settingsphp_filename
		mv $sites_default_path/original.settings.php $sites_default_path/settings.php
	fi

}

_install_settingsphp_check() {
	settingsphp_check_command="$drush settingsphp-generate --help"
	if [ ! "$($settingsphp_check_command 2>/dev/null)" ]
		then
		drop_info "Installing settingsphp.module..."
		$drush dl settingsphp -y
		$drush cc drush -y
	fi
}

_install_profile() {
	local __profile=$1
	debug $drush --root=$drop_docroot si $__profile $force_yes
}

_import_db() {
	local __db_dump=$1
	drop_info "making sure the current database is empty"
	debug $drush --root=$drop_docroot sql-drop $force_yes
	drop_info "Importing DB Dump from $__db_dump"
	debug $drush --root=$drop_docroot sql-cli < $__db_dump
	drop_info "Rebuilding registry..."
	. $script_root/lib/registry_rebuild.inc.sh
	registry_rebuild $drop_docroot 1>/dev/null
}

main
