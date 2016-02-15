#!/bin/bash
# Usage: ./build.sh [--purge]
set -e

purge=false
[[ $1 = "--purge" ]] && purge=true


main() {

	echo "Prepare the build path at $config_build_path"
	_prepare_build_path

	echo "Build the codebase in $config_build_path"
	_build_codebase

	if [ -d "$config_profile_path" ]
		then
		echo "Build the profile if required"
		_build_profile
	fi

	_build_files
}
_prepare_build_path() {
	if [ "$purge" = "true" ] && [ -d "$config_build_path" ]
		then
		echo "Destroying the previous build (if exists)"
		chmod -R u+w $config_build_path
		rm -rf $config_build_path
	fi
	mkdir -p $config_build_path
	config_build_path=$(_get_abs_path $config_build_path)
	[[ -d $config_build_path/sites/default ]] && chmod -R u+w $config_build_path/sites/default
	return 0
}
_build_codebase() {
	cd $config_build_path
	drush make $_config_profile_makefile_path .
	return 0
}
_build_profile() {	
	# Link the profile to the codebase
	if [ "$config_build_symlink_to_profile" = true ]
	  then
	  echo "Creating a symlink to profile at $config_profile_path"
	  debug ln -nfs $config_profile_path $config_build_path/profiles/$config_profile_name
	else
	  echo "Deploying profile from $config_profile_path"
	  rm -rf $config_build_path/profiles/$config_profile_name
	  cp -r $config_profile_path/ $config_build_path/profiles/$config_profile_name
	  rm -rf $config_build_path/profiles/$config_profile_name/.git*
	fi
	return 0
}
_build_files() {
	# Link files directory
	[[ $config_build_files ]] && ln -nfs $config_build_files $config_build_path/sites/default/files
	return 0
}

main

echo "Build finished successfully."
return 0
