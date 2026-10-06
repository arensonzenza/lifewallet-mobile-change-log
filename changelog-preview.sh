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

  # Heading: "## [<version+build>] <date>"
  # Unreleased: version from pubspec.yaml and today's date.
  # Released: the released version and the date saved by `change release`.
  if [ "$raw_version" == "Unreleased" ]; then
    heading_version=$(_changelogsh_pubspec_version)
    heading_date=$(date +"%Y-%m-%d")
    if [ -z "$heading_version" ]; then
      heading_version="Unreleased"
    fi
  else
    heading_version=$raw_version
    heading_date=$(cat "changelog/$expanded/.released" 2>/dev/null)
  fi
  heading="## [$heading_version]"
  if [ -n "$heading_date" ]; then
    heading="$heading $heading_date"
  fi

  echo "# What's new?"
  echo ""
  echo "$heading"
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
