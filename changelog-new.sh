#!/bin/bash

function _changelogsh_new {
  timestamp=$(date +"%Y%m%d%H%M%S")
  type='fixed'

  if [ "$#" -ge 1 ]; then
    type=$1
  fi

  # Entries are filed under the version+build in pubspec.yaml at the time they are added.
  # Without a pubspec.yaml they go to changelog/unreleased.
  target='unreleased'
  current=$(_changelogsh_current_version)
  if [ -n "$current" ]; then
    target=$(_changelogsh_raw_to_expanded $current)
  fi

  mkdir -p "changelog/$target/$type"

  if [ "$#" -ge 2 ]; then
    # never overwrite an entry created in the same second
    while [ -e "changelog/$target/$type/$timestamp" ]; do
      timestamp=$((timestamp + 1))
    done
    echo ${@:2} > "changelog/$target/$type/$timestamp"
  fi
}
