#!/bin/bash

function _changelogsh_release {
  if [ "$#" -lt 1 ]; then
    echo "Version is required"
    return
  fi

  version=$(_changelogsh_normalize_version $1)
  base=$(_changelogsh_raw_to_expanded ${version%%+*})
  unreleased='changelog/unreleased'

  # "change release 1.90.0+93" releases that build only.
  # "change release 1.90.0" releases every unreleased build of 1.90.0, plus entries that have no version+build.
  moved=""
  if [[ "$version" == *+* ]]; then
    b=$(_changelogsh_raw_to_expanded $version)
    if [ -d "$unreleased/$b" ]; then
      mkdir -p "changelog/$base/$b"
      _changelogsh_merge_dir "$unreleased/$b" "changelog/$base/$b"
      moved="yes"
    fi
  else
    for b in $(_changelogsh_build_folders $unreleased); do
      if [ "${b:0:9}" == "$base" ]; then
        mkdir -p "changelog/$base/$b"
        _changelogsh_merge_dir "$unreleased/$b" "changelog/$base/$b"
        moved="yes"
      fi
    done
    if _changelogsh_has_flat_entries $unreleased; then
      mkdir -p "changelog/$base"
      for dir in $unreleased/[a-z]*; do
        [ -d "$dir" ] && mkdir -p "changelog/$base/$(basename $dir)" && \
          for file in "$dir"/*; do [ -e "$file" ] && mv "$file" "changelog/$base/$(basename $dir)/"; done
        rmdir "$dir" 2>/dev/null
      done
      moved="yes"
    fi
  fi

  if [ -z "$moved" ]; then
    printf "Nothing to release for $version.\n"
    return
  fi

  date +"%Y-%m-%d" > "changelog/$base/.released"
  # Version history: the app version (pubspec.yaml) at the time of release
  app_version=$(_changelogsh_pubspec_version)
  if [ -n "$app_version" ]; then
    echo "$app_version" > "changelog/$base/.version"
  fi

  _changelogsh_preview $version
}
