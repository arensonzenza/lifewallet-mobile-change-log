#!/bin/bash

function _changelogsh_release {
  if [ ! -d "changelog/unreleased/" ]; then
    printf "Nothing to release.\n"
    return
  fi

  if [ "$#" -lt 1 ]; then
    echo "Version is required"
    return
  fi

  version=$(_changelogsh_normalize_version $1)
  expanded=$(_changelogsh_raw_to_expanded $version)
  if [ -d "changelog/$expanded" ]; then
    printf "$version is already released. Run 'change unrelease $version' first.\n"
    return
  fi

  mv 'changelog/unreleased' "changelog/$expanded"
  date +"%Y-%m-%d" > "changelog/$expanded/.released"

  _changelogsh_preview $version
}
