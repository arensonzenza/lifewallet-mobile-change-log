#!/bin/bash

function _changelogsh_preview_hint {
  if _changelogsh_has_unreleased; then
    echo "Note: changelog/unreleased has entries that belong to no version."
    echo "Run 'change release <version>' to assign them to a version."
  fi
}

# Prints one "## [version] date" block with its types. Args: folder-name, version label
function _changelogsh_preview_section {
  expanded="$1"
  raw_version="$2"
  current=$(_changelogsh_current_version)

  # Heading date: the release date if released; today for the version being worked on
  heading_date=$(cat "changelog/$expanded/.released" 2>/dev/null)
  if [ -z "$heading_date" ]; then
    if [ "$raw_version" == "Unreleased" ] || [ "$raw_version" == "$current" ]; then
      heading_date=$(date +"%Y-%m-%d")
    fi
  fi
  heading="## [$raw_version]"
  if [ -n "$heading_date" ]; then
    heading="$heading $heading_date"
  fi

  echo "$heading"
  for dir in changelog/$expanded/*; do
    if [ -d "$dir" ] && [ "$(ls -A $dir)" ]; then
      current_type=$(echo $dir | grep -o '[^/]*$')
      echo "###" $(_changelogsh_title $current_type)
      # files are ordered oldest to newest; for duplicate lines only the latest is kept
      for file in $dir/*; do
        echo "-" $(cat $file)
      done | awk '{ line[NR] = $0; last[$0] = NR } END { for (i = 1; i <= NR; i++) if (last[line[i]] == i) print line[i] }'
      echo ""
    fi
  done
}

function _changelogsh_preview {
  current=$(_changelogsh_current_version)

  # Which version to show: the one given, else the pubspec.yaml version, else unreleased
  if [ "$#" -gt 0 ]; then
    if [ "$(echo $1 | tr '[:upper:]' '[:lower:]')" == "unreleased" ]; then
      raw_version="Unreleased"
    else
      raw_version=$(_changelogsh_normalize_version $1)
    fi
  elif [ -n "$current" ]; then
    raw_version=$current
  else
    raw_version="Unreleased"
  fi

  if [ "$raw_version" == "Unreleased" ]; then
    folders="unreleased"
    [ -d "changelog/unreleased" ] || folders=""
  else
    folders=$(_changelogsh_version_folders $raw_version)
  fi

  if [ -z "$folders" ]; then
    if [ "$#" -eq 0 ] && [ -n "$current" ]; then
      printf "No changes for $raw_version yet.\n"
      _changelogsh_preview_hint
    else
      printf "$raw_version not found.\n"
    fi
    return
  fi

  echo "# What's new?"
  echo ""
  # One section per version+build, newest first
  for folder in $folders; do
    if [ "$folder" == "unreleased" ]; then
      _changelogsh_preview_section unreleased Unreleased
    else
      _changelogsh_preview_section $folder $(_changelogsh_folder_to_version $folder)
    fi
  done

  if [ "$#" -eq 0 ]; then
    _changelogsh_preview_hint
  fi
}
