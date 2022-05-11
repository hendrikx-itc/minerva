#!/bin/bash
#set -e

TESTS_DIR="/tests"
RESULTS_DIR="/test_results"

ls "$TESTS_DIR"

echo "Running Tests..."
find $TESTS_DIR -type f -name '*.sql' | while read filepath
do
  filename=${filepath##*/}
  without_prefix=${filepath#*$TESTS_DIR}
  without_prefix_and_ext=${without_prefix%.sql}
  tapfilepath="$RESULTS_DIR$without_prefix_and_ext.tap"
  tapfiledir=${tapfilepath%/*}
  mkdir -p "$tapfiledir"
  echo "* $filepath -> $tapfilepath"
  PGUSER="$POSTGRES_USER" PGDATABASE=minerva pg_prove --verbose $filepath > $tapfilepath
done

exit 1
