#!/bin/bash
# Usage: drop -- build
set -e

_config_makefile_purge=true
[ "$config_makefile_purge" ] && _config_makefile_purge=$config_makefile_purge

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
	if [ "$config_deploy_docroot" = "symlink" ]
		then
		echo "Using the source at $config_codebase_path"
		_purge_build_path
		# @FIXME needs to be added to config, validated and tested
		debug ln -nFs $config_codebase_path $drop_docroot
	elif [ "$config_deploy_docroot" = "makefile" ]
		then
		_validate_makefile
		echo "Using the makefile $config_makefile_path"
		if [ "$_config_makefile_purge" = "true" ]; then
			echo "Destroying the existing build"
			_purge_build_path
			debug drush make $config_makefile_path $drop_docroot
		else
			echo "Re-building the existing directory."
			_prepare_build_path
			cd $drop_docroot
			debug drush make $config_makefile_path .
		fi
	else
		echo "No source found."
		exit 1
	fi
	return 0
}
_build_profile() {	
	[ "$config_deploy_profile" ] && _validate_profile

	if [ "$config_deploy_profile" = "symlink" ]
	  then
	  echo "Creating a symlink to profile at $config_profile_path"
	  debug rm -rf $drop_docroot/profiles/$config_profile_name
	  debug ln -nfs $config_profile_path $drop_docroot/profiles/$config_profile_name
	elif [ "$config_deploy_profile" = "copy" ]
	  then
	  echo "Deploying profile from $config_profile_path"
	  rm -rf $drop_docroot/profiles/$config_profile_name
	  cp -r $config_profile_path/ $drop_docroot/profiles/$config_profile_name
	  rm -rf $drop_docroot/profiles/$config_profile_name/.git*
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
