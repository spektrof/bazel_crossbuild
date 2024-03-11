#!/bin/sh

set -ue

OUTPUT_FILE=$1

tee -a $1 <<EOF
echo "Pass"
EOF
