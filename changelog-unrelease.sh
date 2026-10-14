#!/bin/bash

function _changelogsh_unrelease {
  if [ "$#" -eq 0 ]; then
    echo "Version is required"
    return
  fi

  version=$(_changelogsh_normalize_version $1)
  base=$(_changelogsh_raw_to_expanded ${version%%+*})
  unreleased='changelog/unreleased'

  if [ ! -d "changelog/$base" ]; then
    printf "$version not found.\n"
    return
  fi

  # "change unrelease 1.90.0+93" moves that build back; "change unrelease 1.90.0" moves everything back.
  # Entries are merged file by file, so nothing in unreleased is overwritten.
  if [[ "$version" == *+* ]]; then
    b=$(_changelogsh_raw_to_expanded $version)
    if [ ! -d "changelog/$base/$b" ]; then
      printf "$version not found.\n"
      return
    fi
    mkdir -p "$unreleased/$b"
    _changelogsh_merge_dir "changelog/$base/$b" "$unreleased/$b"
  else
    for b in $(_changelogsh_build_folders "changelog/$base"); do
      mkdir -p "$unreleased/$b"
      _changelogsh_merge_dir "changelog/$base/$b" "$unreleased/$b"
    done
    _changelogsh_merge_dir "changelog/$base" "$unreleased"
  fi

  # Drop the released marks once nothing is left in the version
  if [ -z "$(_changelogsh_build_folders changelog/$base)" ] && ! _changelogsh_has_flat_entries "changelog/$base"; then
    rm -f "changelog/$base/.released" "changelog/$base/.version" "changelog/$base/.name"
    rmdir "changelog/$base" 2>/dev/null
  fi

  _changelogsh_preview
}
