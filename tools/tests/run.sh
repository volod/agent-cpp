#!/bin/sh
# Runs every tools/tests/*_test.sh; exit 1 when any of them fails.
set -u
dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
status=0
for test in "$dir"/*_test.sh; do
  sh "$test" || status=1
done
exit "$status"
