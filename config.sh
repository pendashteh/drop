#!/bin/bash
# Usage: $ drop -- config
set -e

vars=($(compgen -A variable | grep "config_"))
for var in ${vars[@]}
do
	eval "echo $var=\$$var"
done