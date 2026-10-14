#!/bin/bash

# Prints every version+build section found in a folder, newest build first
function _changelogsh_preview_builds {
  local folder="$1" only="$2" b
  for b in $(_changelogsh_build_folders $folder); do
    if [ -z "$only" ] || [ "$b" == "$only" ]; then
      _changelogsh_print_section "$folder/$b" "$(_changelogsh_folder_to_version $b)" "$(_changelogsh_latest_entry_date $folder/$b)"
    fi
  done
}

function _changelogsh_preview {
  # "change preview release 7.0" is the same as "change preview 7.0"
  if [ "$#" -ge 2 ] && [ "$(echo $1 | tr '[:upper:]' '[:lower:]')" == "release" ]; then
    shift
  fi

  raw_version="Unreleased"
  if [ "$#" -gt 0 ] && [ "$(echo $1 | tr '[:upper:]' '[:lower:]')" != "unreleased" ]; then
    raw_version=$(_changelogsh_normalize_version $1)
  fi

  if [ "$raw_version" == "Unreleased" ]; then
    unreleased='changelog/unreleased'
    if [ -z "$(_changelogsh_build_folders $unreleased)" ] && ! _changelogsh_has_flat_entries $unreleased; then
      printf "Unreleased not found.\n"
      return
    fi
    echo "# What's new?"
    echo ""
    echo "## Unreleased"
    echo ""
    _changelogsh_preview_builds $unreleased
    if _changelogsh_has_flat_entries $unreleased; then
      # entries added without a version+build
      label=$(_changelogsh_pubspec_version)
      [ -z "$label" ] && label="Unreleased"
      _changelogsh_print_section $unreleased "$label" "$(date +"%Y-%m-%d")"
    fi
    return
  fi

  # A released version: changelog/<version>/<version+build>/...
  base=$(_changelogsh_raw_to_expanded ${raw_version%%+*})
  only=""
  if [[ "$raw_version" == *+* ]]; then
    only=$(_changelogsh_raw_to_expanded $raw_version)
  fi

  if [ -d "changelog/$base" ] && { [ -z "$only" ] || [ -d "changelog/$base/$only" ] || _changelogsh_has_flat_entries "changelog/$base"; }; then
    echo "# What's new?"
    echo ""
    release_name=$(cat "changelog/$base/.name" 2>/dev/null)
    [ -z "$release_name" ] && release_name=${raw_version%%+*}
    echo "## Release $release_name"
    echo ""
    _changelogsh_preview_builds "changelog/$base" $only
    if [ -z "$only" ] && _changelogsh_has_flat_entries "changelog/$base"; then
      # released without version+build sections (older releases): use the app version saved at release
      label=$(cat "changelog/$base/.version" 2>/dev/null)
      [ -z "$label" ] && label=$raw_version
      _changelogsh_print_section "changelog/$base" "$label" "$(cat changelog/$base/.released 2>/dev/null)"
    fi
  elif [ -n "$only" ] && [ -d "changelog/unreleased/$only" ]; then
    echo "# What's new?"
    echo ""
    echo "## Unreleased"
    echo ""
    _changelogsh_preview_builds changelog/unreleased $only
  else
    printf "$raw_version not found.\n"
  fi
}
