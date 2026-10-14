#!/bin/bash

function _changelogsh_unrelease {
  if [ "$#" -eq 0 ]; then
    echo "Version is required"
    return
  fi

  version=$(_changelogsh_normalize_version $1)
  folders=$(_changelogsh_version_folders $version)

  if [ -z "$folders" ]; then
    printf "$version not found.\n"
    return
  fi

  # Entries stay in their version folder; only the released mark is removed
  # (one build for "1.90.0+93", every build for "1.90.0")
  for folder in $folders; do
    rm -f "changelog/$folder/.released"
  done

  _changelogsh_preview $version
}
