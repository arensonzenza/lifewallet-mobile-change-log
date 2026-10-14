#!/bin/bash

function _changelogsh_release {
  if [ "$#" -lt 1 ]; then
    echo "Version is required"
    return
  fi

  version=$(_changelogsh_normalize_version $1)
  expanded=$(_changelogsh_raw_to_expanded $version)

  # Entries left in changelog/unreleased are assigned to this version
  if _changelogsh_has_unreleased; then
    if [ ! -f "changelog/$expanded/.released" ]; then
      for dir in changelog/unreleased/*; do
        if [ -d "$dir" ]; then
          type=$(basename "$dir")
          mkdir -p "changelog/$expanded/$type"
          for file in "$dir"/*; do
            if [ -e "$file" ]; then
              mv "$file" "changelog/$expanded/$type/"
            fi
          done
        fi
      done
    fi
  fi

  folders=$(_changelogsh_version_folders $version)
  if [ -z "$folders" ]; then
    printf "Nothing to release for $version.\n"
    return
  fi

  # Mark every matching version+build as released, each with its own date.
  # "change release 1.90.0+93" releases that build; "change release 1.90.0" releases every build of 1.90.0.
  released=""
  for folder in $folders; do
    v=$(_changelogsh_folder_to_version $folder)
    if [ -f "changelog/$folder/.released" ]; then
      printf "$v is already released. Run 'change unrelease $v' first.\n"
    else
      date +"%Y-%m-%d" > "changelog/$folder/.released"
      released="yes"
    fi
  done

  if [ -n "$released" ]; then
    _changelogsh_preview $version
  fi
}
