**Drop manages your Drupal project for you**

```
	$ drop init
	$ drop -- build
	$ drop mytestenv.yml install
	$ drop live.yml script scripts/sync-content.sh
	$ drop ./docroot fix-missing-modules
	$ drop ../v2/docroot drush cc all
```

# Available commands
`fix-missing-modules` Fixes the missing module error message. [https://www.drupal.org/project/module_missing_message_fixer]

TODO
- get database as a prefix when installing
- add list of all commands
