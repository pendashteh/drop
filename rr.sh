#!/bin/bash
# Usage: drop -- rebuild
set -e

$php $script_root/scripts/rr.php --root=$drop_docroot
