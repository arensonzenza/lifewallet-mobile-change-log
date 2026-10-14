#!/bin/bash

# change release summary <version>
# Wraps every build released under a version into one list per type, with duplicates removed
# (the latest entry is kept), saves it as changelog/<version>/.summary and prints it.
function _changelogsh_release_summary {
  if [ "$#" -lt 1 ]; then
    echo "Version is required"
    return
  fi

  local version base name types type files out
  version=$(_changelogsh_normalize_version $1)
  base=$(_changelogsh_raw_to_expanded ${version%%+*})

  if [ ! -d "changelog/$base" ]; then
    printf "${version%%+*} not found. Run 'change release $1' first.\n"
    return
  fi

  name=$(cat "changelog/$base/.name" 2>/dev/null)
  [ -z "$name" ] && name=${version%%+*}

  types=$(for d in changelog/$base/*/* changelog/$base/*; do
    [ -d "$d" ] && basename "$d"
  done | grep -v '^[0-9]' | sort -u)

  out="# What's new?
"
  out="$out
## Release $name
"
  for type in $types; do
    # entries of all builds, oldest to newest (file names are timestamps); for duplicates the latest is kept
    files=$(for f in changelog/$base/*/$type/* changelog/$base/$type/*; do
      [ -f "$f" ] && echo "${f##*/} $f"
    done | sort | cut -d' ' -f2-)
    if [ -n "$files" ]; then
      out="$out
### $(_changelogsh_title $type)
$(for f in $files; do echo "-" $(cat $f); done | awk '{ line[NR] = $0; last[$0] = NR } END { for (i = 1; i <= NR; i++) if (last[line[i]] == i) print line[i] }')
"
    fi
  done

  echo "$out" > "changelog/$base/.summary"
  echo "$out"
}

function _changelogsh_release {
  if [ "$#" -ge 1 ] && [ "$(echo $1 | tr '[:upper:]' '[:lower:]')" == "summary" ]; then
    _changelogsh_release_summary ${@:2}
    return
  fi

  if [ "$#" -lt 1 ]; then
    echo "Version is required"
    return
  fi

  version=$(_changelogsh_normalize_version $1)
  base=$(_changelogsh_raw_to_expanded ${version%%+*})
  unreleased='changelog/unreleased'

  # "change release 1.90.0+93" releases that build only.
  # "change release 7.0" releases everything that is unreleased under the release name 7.0.0;
  # every build keeps its own section, so builds are never mixed.
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
      mkdir -p "changelog/$base/$b"
      _changelogsh_merge_dir "$unreleased/$b" "changelog/$base/$b"
      moved="yes"
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
  # Remember the release name as typed (7.0 stays 7.0, not 7.0.0)
  name="${1%%+*}"
  echo "$name" > "changelog/$base/.name"
  # Version history: the app version (pubspec.yaml) at the time of release
  app_version=$(_changelogsh_pubspec_version)
  if [ -n "$app_version" ]; then
    echo "$app_version" > "changelog/$base/.version"
  fi

  _changelogsh_preview $version
}
