#!/bin/bash

function _changelogsh_new {
  timestamp=$(date +"%Y%m%d%H%M%S")
  type='fixed'

  if [ "$#" -ge 1 ]; then
    type=$1
  fi

  # New entries are always unreleased. They are kept per version+build (from pubspec.yaml):
  # changelog/unreleased/<version+build>/<type>/. Without a pubspec.yaml: changelog/unreleased/<type>/.
  target='changelog/unreleased'
  current=$(_changelogsh_current_version)
  if [ -n "$current" ]; then
    target="$target/$(_changelogsh_raw_to_expanded $current)"
  fi

  mkdir -p "$target/$type"

  if [ "$#" -ge 2 ]; then
    # never overwrite an entry created in the same second
    while [ -e "$target/$type/$timestamp" ]; do
      timestamp=$((timestamp + 1))
    done
    echo ${@:2} > "$target/$type/$timestamp"
  fi
}
