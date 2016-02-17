
To install the website you need to:
1. Get the repository containg Drupal profile and make file
2. Build the codebase using the make file
3. Install Drupal using the profile

To help with the process, you could simply use the provided scripts.
You may also want to update scripts/config.sh for convenience

$ git clone repo_path repo
$ cd repo
$ ./scripts/build.sh
$ ./scripts/install.sh

This will create _build directory which has a symlink to profile directory.

If any *.make file is changed to rebuild the code base just run build.sh again
$ ./scripts/build.sh

