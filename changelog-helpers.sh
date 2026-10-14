#!/bin/bash

function _changelogsh_title {
  input=$1
  echo $(echo ${input:0:1} | tr '[a-z]' '[A-Z]')${input:1}
}

function _changelogsh_raw_to_expanded {
  input="$1"
  # Flutter style "1.4.0+12": treat the build number as a 4th part
  input="${input//+/.}"
  split=("${input//./ }")
  echo $split | xargs printf '%03d'
}

function _changelogsh_expanded_to_raw {
  input=$1
  split=($(echo $input | fold -w3))
  echo $split | sed 's/^0*//g; s/ 0*/./g'
}

# Reads "version: 1.4.0+12" from pubspec.yaml in the current directory
function _changelogsh_pubspec_version {
  if [ -f 'pubspec.yaml' ]; then
    grep -m1 '^version:' pubspec.yaml | sed 's/^version:[[:space:]]*//' | tr -d '\r"'"'"' '
  fi
}

# Pads a version to at least major.minor.patch: 7 -> 7.0.0, 7.0 -> 7.0.0, 7.0+3 -> 7.0.0+3
function _changelogsh_normalize_version {
  input="$1"
  base="${input%%+*}"
  build=""
  if [[ "$input" == *+* ]]; then
    build="+${input#*+}"
  fi
  IFS='.' read -ra parts <<< "$base"
  while [ ${#parts[@]} -lt 3 ]; do
    parts+=(0)
  done
  (IFS='.'; echo "${parts[*]}$build")
}

# Current app version from pubspec.yaml, normalized (e.g. 1.90.0+93). Empty if missing or invalid.
function _changelogsh_current_version {
  v=$(_changelogsh_pubspec_version)
  if [[ "$v" =~ ^[0-9]+(\.[0-9]+)*(\+[0-9]+)?$ ]]; then
    _changelogsh_normalize_version "$v"
  fi
}

# True when changelog/unreleased holds entry files
function _changelogsh_has_unreleased {
  [ -d 'changelog/unreleased' ] && find changelog/unreleased -type f 2>/dev/null | grep -q .
}

# Folder name -> version: 001090000093 -> 1.90.0+93, 001090000 -> 1.90.0
function _changelogsh_folder_to_version {
  f="$1"
  v="$((10#${f:0:3})).$((10#${f:3:3})).$((10#${f:6:3}))"
  if [ ${#f} -gt 9 ]; then
    v="$v+$((10#${f:9:3}))"
  fi
  echo "$v"
}

# Folders (newest first) that belong to a version.
#   1.90.0+93 -> only that build
#   1.90.0    -> 1.90.0 itself plus every build of it (1.90.0+93, 1.90.0+94, ...)
function _changelogsh_version_folders {
  raw="$1"
  expanded=$(_changelogsh_raw_to_expanded $raw)
  if [[ "$raw" == *+* ]]; then
    [ -d "changelog/$expanded" ] && echo "$expanded"
  else
    for d in changelog/${expanded}???  changelog/${expanded}; do
      [ -d "$d" ] && basename "$d"
    done | sort -r
  fi
}
