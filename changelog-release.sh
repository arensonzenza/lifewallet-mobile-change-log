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

  name=$(_changelogsh_release_field "changelog/$base" name)
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

function _changelogsh_release_run {
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

  # One hidden file with the release details: the name as typed (7.0 stays 7.0, not 7.0.0),
  # the release date, and the app version (pubspec.yaml) at the time of release
  {
    echo "name=${1%%+*}"
    echo "released=$(date +"%Y-%m-%d")"
    echo "version=$(_changelogsh_pubspec_version)"
  } > "changelog/$base/.release"
  rm -f "changelog/$base/.name" "changelog/$base/.released" "changelog/$base/.version"

  _changelogsh_preview $version
}

# change release <version> [--skip <text>]...
# Entries that contain <text> (case-insensitive, e.g. a ticket like LW-198) are left out of the
# release and stay in changelog/unreleased/ for the next one.
function _changelogsh_release {
  local args=() skips=() hold file rel text matched kept=""
  while [ "$#" -gt 0 ]; do
    if [ "$1" == "--skip" ]; then
      if [ -z "$2" ]; then
        echo "--skip needs the text of the change to leave out, e.g. --skip LW-198"
        return
      fi
      skips+=("$2")
      shift 2
    else
      args+=("$1")
      shift
    fi
  done

  if [ ${#skips[@]} -eq 0 ]; then
    _changelogsh_release_run "${args[@]}"
    return
  fi

  if [ ! -d "changelog/unreleased" ]; then
    printf "Nothing to release.\n"
    return
  fi

  # Every --skip must match something, otherwise a typo would release the change by accident.
  for text in "${skips[@]}"; do
    matched=""
    while IFS= read -r file; do
      if grep -qiF -- "$text" "$file"; then matched="yes"; break; fi
    done < <(find changelog/unreleased -type f ! -name '.*')
    if [ -z "$matched" ]; then
      printf "No unreleased change matches '%s'. Nothing was released.\n" "$text"
      return
    fi
  done

  # Set the skipped entries aside, release the rest, then put them back in unreleased.
  hold=$(mktemp -d)
  while IFS= read -r file; do
    for text in "${skips[@]}"; do
      if grep -qiF -- "$text" "$file"; then
        rel=${file#changelog/unreleased/}
        mkdir -p "$hold/$(dirname "$rel")"
        kept="$kept- $(cat "$file")\n"
        mv "$file" "$hold/$rel"
        break
      fi
    done
  done < <(find changelog/unreleased -type f ! -name '.*')

  _changelogsh_release_run "${args[@]}"

  mkdir -p changelog/unreleased
  (cd "$hold" && find . -type f) | while IFS= read -r file; do
    rel=${file#./}
    mkdir -p "changelog/unreleased/$(dirname "$rel")"
    mv "$hold/$rel" "changelog/unreleased/$rel"
  done
  rm -rf "$hold" 2>/dev/null

  printf "\nLeft in unreleased:\n$kept"
}
