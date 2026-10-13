#!/bin/bash

function _changelogsh_preview {
  raw_version="Unreleased"
  expanded="unreleased"

  if [ "$#" -gt 0 ]; then
    raw_version=$(_changelogsh_normalize_version $1)
  fi

  if [ $raw_version != "Unreleased" ]; then
    expanded=$(_changelogsh_raw_to_expanded $raw_version)
  fi

  if [ ! -d "changelog/$expanded" ]; then
    printf "$raw_version not found.\n"
    return
  fi

  # Unreleased: "## Unreleased", then "## [<version+build>] <date>" (version from pubspec.yaml, today's date).
  # Released:   "## Release <version>", then "## [<version+build>] <date>" (date saved by `change release`).
  echo "# What's new?"
  echo ""
  if [ "$raw_version" == "Unreleased" ]; then
    echo "## Unreleased"
    echo ""
    heading_version=$(_changelogsh_pubspec_version)
    heading_date=$(date +"%Y-%m-%d")
  else
    echo "## Release ${raw_version%%+*}"
    echo ""
    heading_version=$raw_version
    heading_date=$(cat "changelog/$expanded/.released" 2>/dev/null)
  fi
  if [ -n "$heading_version" ]; then
    heading="## [$heading_version]"
    if [ -n "$heading_date" ]; then
      heading="$heading $heading_date"
    fi
    echo "$heading"
  fi
  for dir in changelog/$expanded/*; do
    if [ "$(ls -A $dir)" ]; then
      current=$(echo $dir | grep -o '[^/]*$')
      echo "###" $(_changelogsh_title $current)
      # files are ordered oldest to newest; for duplicate lines only the latest is kept
      for file in $dir/*; do
        echo "-" $(cat $file)
      done | awk '{ line[NR] = $0; last[$0] = NR } END { for (i = 1; i <= NR; i++) if (last[line[i]] == i) print line[i] }'
      echo ""
    fi
  done
}
