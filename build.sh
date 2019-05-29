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
	drop_info "Purging build path"
	if [ -L "$drop_docroot" ] || [ -d "$drop_docroot" ]
		then
		drop_info "Applying force"
		chmod -R u+w $drop_docroot
		rm -rf $drop_docroot
	fi
	drop_info "Done"
}
_prepare_build_path() {
	mkdir -p $drop_docroot
	drop_docroot=$(_get_abs_path $drop_docroot)
	[[ -d $drop_docroot/sites/default ]] && chmod -R u+w $drop_docroot/sites/default
	return 0
}
_build_codebase() {
	if [ "$config_build_makefile" ]
		then
		_validate_makefile
		echo "Using the makefile $config_build_makefile"
		_purge_build_path
		# Check if the profile needs to be symlink
		if [ "$config_profile_symlink" = "true" ]; then
			_validate_profile
			# First get only core and skip the profile
			debug $drush make $config_build_makefile $drop_docroot --no-recursion
			# Then make all the profile dependencies into sites/all
			local _profile_makefile_path="$config_profile_path/drupal-org.make"
			if [ -e "$_profile_makefile_path" ]; then
				debug $drush make $_profile_makefile_path $drop_docroot --no-core --contrib-destination="sites/all"
			fi
		else
			debug $drush make $config_build_makefile $drop_docroot
		fi
	elif [ "$config_build_docroot_type" = "git" ]; then
		echo "Building docroot at '$drop_docroot' by cloning '$config_build_docroot_url'"
		_purge_build_path
		git_url=$config_build_docroot_url
		git_destination=$drop_docroot
		git_branch=$config_build_docroot_branch
		_git_deploy $git_url $git_destination $git_branch
	else
		echo "No source is provided to build the codebase."
	fi
	return 0
}

_git_deploy () {
	local __git_url=$1
	local __git_destination=$2
	local __git_branch_arg="" && [ ! -z "$3" ] && __git_branch_arg="-b $3"
	local __git_clone_args="--depth 1" && [ ! -z "$4" ] && local __git_clone_args=$4

	$git clone $__git_clone_args $__git_branch_arg $__git_url $__git_destination

	return 0
}

_build_profile() {
	_profile_path=$drop_docroot/profiles/$config_profile_name
	if [ "$config_build_profile_type" = "symlink" ]
	  then
		_validate_profile
	  echo "Creating a symlink to profile at $config_build_profile_path"
	  debug rm -rf $drop_docroot/profiles/$config_profile_name
	  debug ln -nfs $config_build_profile_path $drop_docroot/profiles/$config_profile_name
	elif [ "$config_build_profile_type" = "git" ]; then
		_git_url=$config_build_profile_url
		[ ! -z "$config_build_profile_branch" ] && _git_branch=$config_build_profile_branch
		_git_dir=$drop_docroot/profiles/$config_profile_name
		echo "Building docroot at $_git_dir by cloning $_git_url"
		$git clone $_git_url $_git_dir
		[ ! -z "$_git_branch" ] && $git --work-tree=$_git_dir --git-dir=$_git_dir/.git checkout -f $_git_branch
	elif [ "$config_build_profile_type" = "copy" ]
	  then
		_validate_profile
		echo "Copying the profile from $config_build_profile_path as profiles/$config_profile_name"
		debug rm -rf $drop_docroot/profiles/$config_profile_name
		debug cp -r $config_build_profile_path $drop_docroot/profiles/$config_profile_name
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
