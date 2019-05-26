#!/bin/bash
# Usage: drop -- rebuild
set -e

# Displays INFO messages on the shell
drop_info () {
  local __message=$1
  echo "[INFO]" $__message
}
