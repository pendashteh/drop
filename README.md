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

## fix-missing-modules
Fixes the missing module error message. [https://www.drupal.org/project/module_missing_message_fixer]

## db-sql [--no-db] SQL
Runs an SQL Query against database. You can choose to omit the database auto-detection.
```
$ drop drop.yml db-sql select nid, type, title, from node
$ drop drop.yml db-sql --no-db "create database new_db; use new_db; create table example (name varchar(20) not null);"

```


TODO
- get database as a prefix when installing
- add list of all commands
