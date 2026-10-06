#!/bin/bash

function _changelogsh_unrelease {
  if [ "$#" -eq 0 ]; then
    echo "Version is required"
    return
  fi

  version=$(_changelogsh_normalize_version $1)
  expanded=$(_changelogsh_raw_to_expanded $version)

  if [ ! -d "changelog/$expanded" ]; then
    printf "$version not found.\n"
    return
  fi

  if [ ! -d 'changelog/unreleased' ]; then
    mkdir 'changelog/unreleased'
  fi

  # merge each type folder; never overwrite or drop entries already in unreleased
  for dir in changelog/$expanded/*; do
    if [ -d "$dir" ]; then
      type=$(basename "$dir")
      mkdir -p "changelog/unreleased/$type"
      for file in "$dir"/*; do
        if [ -e "$file" ]; then
          mv "$file" "changelog/unreleased/$type/"
        fi
      done
    fi
  done
  rm -r changelog/$expanded

  _changelogsh_preview
}
