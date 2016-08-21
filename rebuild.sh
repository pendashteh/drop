#!/bin/bash
# Usage: drop -- rebuild
set -e

main() {

	echo "Re-build the codebase in $drop_docroot"
	_build_codebase

	echo "Re-sync sites direcroty if required"
	_build_sites

	echo "Re-build the profile if required"
	_build_profile

}
_build_codebase() {
	if [ "$config_makefile_path" ]
		then
		# Run the make files from within the docroot
		if [ "$config_profile_name" ]; then
			local _profile_makefile_path="$drop_docroot/profiles/$config_profile_name/drupal-org.make"
			if [ -e "$_profile_makefile_path" ]; then
				cd $drop_docroot
				debug drush make $_profile_makefile_path . --no-core
			else
				echo "No makefile found inside the profile ($_profile_makefile_path)"
			fi
		fi
	fi
	return 0
}
_build_profile() {	
	[ "$config_deploy_profile" ] && _validate_profile

	if [ "$config_deploy_profile" = "copy" ]
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

main

echo "Re-build finished successfully."
return 0
