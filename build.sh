#!/bin/bash
# Usage: drop -- build
set -e

main() {

	echo "Build the codebase in $drop_docroot"
	_build_codebase

	echo "Updates the sync direcroty if required"
	_build_sites

	echo "Build the profile if required"
	_build_profile

	echo "Deploy files if required"
	_build_files
}
_purge_build_path() {
	if [ -L "$drop_docroot" ] || [ -d "$drop_docroot" ]
		then
		chmod -R u+w $drop_docroot
		rm -rf $drop_docroot
	fi
}
_prepare_build_path() {
	mkdir -p $drop_docroot
	drop_docroot=$(_get_abs_path $drop_docroot)
	[[ -d $drop_docroot/sites/default ]] && chmod -R u+w $drop_docroot/sites/default
	return 0
}
_build_codebase() {
	if [ "$config_makefile_path" ]
		then
		_validate_makefile
		echo "Using the makefile $config_makefile_path"
		_purge_build_path
		# Check if the profile needs to be symlink
		if [ "$config_profile_symlink" = "true" ]; then
			_validate_profile
			# First get only core and skip the profile
			debug drush make $config_makefile_path $drop_docroot --no-recursion
			# Then make all the profile dependencies into sites/all
			local _profile_makefile_path="$config_profile_path/drupal-org.make"
			if [ -e "$_profile_makefile_path" ]; then
				debug drush make $_profile_makefile_path $drop_docroot --no-core --contrib-destination="sites/all"
			fi
		else
			debug drush make $config_makefile_path $drop_docroot
		fi
	else
		echo "No source is provided to build the codebase."
	fi
	return 0
}
_build_profile() {	
	[ "$config_profile_path" ] && _validate_profile

	if [ "$config_profile_symlink" = "true" ]
	  then
	  echo "Creating a symlink to profile at $config_profile_path"
	  debug rm -rf $drop_docroot/profiles/$config_profile_name
	  debug ln -nfs $config_profile_path $drop_docroot/profiles/$config_profile_name
	fi
	return 0
}
_build_sites() {
	if [ "$config_build_sitesdir" ]
		then
		if [ ! -d "$config_build_sitesdir" ]
			then
			echo "Sites directory was not found at $config_build_sitesdir"
			exit 1
		fi
		echo "Syncing sites dir with $config_build_sitesdir"
		chmod -R u+w $drop_docroot/sites
		debug rsync -av $config_build_sitesdir/ $drop_docroot/sites
	fi
	return 0
}
_build_files() {
	if [ "$config_deploy_files" = "symlink" ]
		then
		echo "Using the source at $config_build_docroot_source"
		rm -rf $drop_docroot/sites/default/files
		# @FIXME needs to be added to config, validated and tested
		ln -nfs $config_files_public $drop_docroot/sites/default/files
	fi
	return 0
}

main

echo "Build finished successfully."
return 0
