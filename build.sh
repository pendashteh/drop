#!/bin/bash
# Usage: ./build.sh [--purge]
set -e

purge=false
[[ $1 = "--purge" ]] && purge=true

main() {

	echo "Build the codebase in $drop_docroot"
	_build_codebase

	echo "Build the profile if required"
	_build_profile

	_build_files
}
_purge_build_path() {
	if [ -e "$drop_docroot" ]
		then
		chmod -R u+w $drop_docroot
		rm -rf $drop_docroot
	fi
}
_prepare_build_path() {
	if [ "$purge" = "true" ]
		then
		echo "Destroying the previous build"
		_purge_build_path
	fi
	mkdir -p $drop_docroot
	drop_docroot=$(_get_abs_path $drop_docroot)
	[[ -d $drop_docroot/sites/default ]] && chmod -R u+w $drop_docroot/sites/default
	return 0
}
_build_codebase() {
	if [ -d "$config_build_docroot_source" ]
		then
		echo "Using the source at $config_build_docroot_source"
		_prepare_build_path
		rm -rf $drop_docroot
		debug ln -nFs $config_build_docroot_source $drop_docroot
	elif [ "$_config_profile_makefile_path" ]
		then
		_validate_makefile
		echo "Using the makefile $_config_profile_makefile_path"
		_prepare_build_path
		cd $drop_docroot
		drush make $_config_profile_makefile_path .
	else
		echo "No source found."
		exit 1
	fi
	return 0
}
_build_profile() {	
	[ "$config_build_profile_method" ] && _validate_profile

	if [ "$config_build_profile_method" = "symlink" ]
	  then
	  echo "Creating a symlink to profile at $config_profile_path"
	  debug ln -nfs $config_profile_path $drop_docroot/profiles/$config_profile_name
	elif [ "$config_build_profile_method" = "copy" ]
	  then
	  echo "Deploying profile from $config_profile_path"
	  rm -rf $drop_docroot/profiles/$config_profile_name
	  cp -r $config_profile_path/ $drop_docroot/profiles/$config_profile_name
	  rm -rf $drop_docroot/profiles/$config_profile_name/.git*
	fi
	return 0
}
_build_files() {
	# Link files directory
	[[ $config_build_files ]] && ln -nfs $config_build_files $drop_docroot/sites/default/files
	return 0
}

main

echo "Build finished successfully."
return 0
