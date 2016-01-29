#!/bin/bash
set -e
_exec_script() {
	path=$(_get_abs_path $1)
	echo "About to execute "$path
	cd $(dirname $path)
	pwd
	. $(basename $path)
}
_get_abs_path() {
	echo $(cd $(dirname $1) && pwd)"/"$(basename $1)
}

script_root=$(dirname ${BASH_SOURCE[0]});
config_profile_name=""

# Set default configs and variables
root=$(pwd)
config_build_path=$root/_build
config_profile_path=$root/profile
config_profile_makefile="stub.make"
config_install_db_dump=false
config_install_features_revert_all=false
config_install_print_uli=false
config_build_symlink_to_profile=true

[ ! -e "$root/config.yml" ] && echo "Please create config.yml file first. @see example.config.yml" && exit 1

# Read local config variables
. $script_root/parse_yaml.sh $root/config.yml "config_"

# Finalize config variables
_config_profile_makefile_path=$config_profile_makefile
[[ ! $_config_profile_makefile_path =~ \/ ]] && _config_profile_makefile_path=$config_profile_path"/"$_config_profile_makefile_path

# Validate config variables:
[[ ! $config_profile_name ]] && echo "Profile name is missing." && exit 1
[[ ! -e $_config_profile_makefile_path ]] && echo "Makefile not found at "$_config_profile_makefile_path && exit 1
[ "$config_install_db_dump" = "true" ] && [[ ! -e $config_install_db_dump ]] && echo "Database dump not found at "$config_install_db_dump && exit 1
[[ ! -e $config_profile_path"/"$config_profile_name".info" ]] && echo "Profile not found at "$config_profile_path && exit 1
[[ $config_build_files ]] && [[ ! -d $config_build_files ]] && echo "Could not locate specified files directory at"$config_build_files && exit 1
[[ $config_install_post_script ]] && [[ ! -e $config_install_post_script ]] && echo "Could not locate post-install script at "$config_install_post_script && exit 1


config_profile_path=$(_get_abs_path $config_profile_path)
config_build_path=$(_get_abs_path $config_build_path)
_config_profile_makefile_path=$(_get_abs_path $_config_profile_makefile_path)
config_install_post_script=$(_get_abs_path $config_install_post_script)


echo "Configuration summary:"
echo "----------------------"
echo "Profile name:" $config_profile_name
echo "Profile path:" $config_profile_path
echo "Makefile path:" $_config_profile_makefile_path
echo "Build path:" $config_build_path
echo "Files directory path:" $config_build_files
echo "Database dump:" $config_install_db_dump
echo "Revert all features:" $config_install_reatures_revert_all
echo "Create a symbolic link to the profile in the repo:" $([ "$config_build_symlink_to_profile" = true ] &&  echo "Yes" || echo "No")
echo "Post-install script:" $([ "$config_install_post_script" ] &&  echo $config_install_post_script || echo "N/A")
echo "----------------------"

if [ ! $(read -p "Are you sure? [y/n] ") = "y" ]
	then
	exit 1
fi
