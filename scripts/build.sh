#!/bin/bash
# Usage: ./build.sh [--purge]
set -e
. $(dirname "$0")/_inc.sh

[[ $1 = "--purge" ]] && echo "Destroying the previous build (if exists)" && chmod -R u+w $config_build_path && rm -rf $config_build_path

echo "Building in "$config_build_path
mkdir -p $config_build_path && cd $config_build_path

[[ -d $config_build_path/sites/default ]] && chmod -R u+w $config_build_path/sites/default

echo "Build the codebase"
drush make $_config_profile_makefile_path .

# Link the profile to the codebase
[ "$config_build_symlink_to_profile" = true ] && ln -nfs $config_profile_path $config_build_path/profiles/$config_profile_name

# Link files directory
[[ $config_build_files ]] && ln -nfs $config_build_files $config_build_path/sites/default/files
