#!/usr/bin/env bash

# Runs the local code generator for the .bin test files (as created/kept
# up-to-date by ./update-bins.sh). Good for local iteration of WIP changes.
#
# Usage:
#
# ./codegen.sh
#
#    Updates generated output for all integration tests.
#
# ./codegen.sh simple value
#
#    Updates generated output only for the 'simple' and 'value' integration test.
#
# Each integration test can optionally have a `parameters.txt` file that will
# be used as the ts-proto_opt... args for generating that test's code.

INTEGRATION_DIR=$(realpath $(dirname "$BASH_SOURCE"))

# Run the code generator in parallel. Note this is purposefully pinned to 5 because
# CI only has 2 cores, but we can go faster than that, and for me locally using all
# 16 cores is overly taxes the machine/kicks on fans/etc. 5 is a good balance.
N=5

echo "Generating typescript code for integration tests using ${N} cores..."

dir=.
if [ -n "${1}" ]; then
  dir="${@}"
fi

cd $INTEGRATION_DIR
list=$(find $dir -name "*.bin" -type f | grep -v dump-response.bin)

for file in $list; do
  echo "${file}"
  # Strip the longest suffix starting at the 1st slash
  dir="${file##./}"
  dir="${dir%%/*}"
  params=""

  if [ -f "${dir}/parameters.txt" ]; then
    params=$(cat "${dir}/parameters.txt")
  fi

  ((i=i%N)); ((i++==0)) && wait
  "../node_modules/.bin/ts-node" "./codegen.ts" "${dir}" "${file}" "${params}" &
done

wait
