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

# Folder name -> version: 001090000093 -> 1.90.0+93, 001090000 -> 1.90.0
function _changelogsh_folder_to_version {
  local f="$1" v
  v="$((10#${f:0:3})).$((10#${f:3:3})).$((10#${f:6:3}))"
  if [ ${#f} -gt 9 ]; then
    v="$v+$((10#${f:9:3}))"
  fi
  echo "$v"
}

# Date (YYYY-MM-DD) of the newest entry under a folder; entry file names are timestamps
function _changelogsh_latest_entry_date {
  local newest
  newest=$(find "$1" -type f 2>/dev/null | awk -F/ '{print $NF}' | grep -E '^[0-9]{14}$' | sort | tail -1)
  if [ -n "$newest" ]; then
    echo "${newest:0:4}-${newest:4:2}-${newest:6:2}"
  fi
}

# Version folders (digits only) inside a folder, newest first
function _changelogsh_build_folders {
  for d in $1/*; do
    [ -d "$d" ] && basename "$d"
  done 2>/dev/null | grep -E '^[0-9]+$' | sort -r
}

# True when a folder directly holds type folders with entries (old style, no version+build in between)
function _changelogsh_has_flat_entries {
  for d in $1/[a-z]*; do
    [ -d "$d" ] && [ "$(ls -A $d)" ] && return 0
  done
  return 1
}

# One "## [version] date" block with its types. Args: folder, version label, date
function _changelogsh_print_section {
  local folder="$1" label="$2" date_text="$3" heading dir file
  heading="## [$label]"
  if [ -n "$date_text" ]; then
    heading="$heading $date_text"
  fi
  echo "$heading"
  for dir in $folder/[a-z]*; do
    if [ -d "$dir" ] && [ "$(ls -A $dir)" ]; then
      echo "###" $(_changelogsh_title $(basename $dir))
      # files are ordered oldest to newest; for duplicate lines only the latest is kept
      for file in $dir/*; do
        echo "-" $(cat $file)
      done | awk '{ line[NR] = $0; last[$0] = NR } END { for (i = 1; i <= NR; i++) if (last[line[i]] == i) print line[i] }'
      echo ""
    fi
  done
}

# Moves everything in folder $1 into folder $2 (merging type folders, never overwriting)
function _changelogsh_merge_dir {
  local src="$1" dst="$2" dir file
  for dir in $src/*; do
    if [ -d "$dir" ]; then
      mkdir -p "$dst/$(basename $dir)"
      for file in "$dir"/*; do
        [ -e "$file" ] && mv "$file" "$dst/$(basename $dir)/"
      done
      rmdir "$dir" 2>/dev/null
    fi
  done
  rmdir "$src" 2>/dev/null
}

# Release details live in one hidden file, changelog/<version>/.release:
#   name=7.0
#   released=2026-10-14
#   version=1.90.0+103
# Usage: _changelogsh_release_field <version folder> <name|released|version>
# Releases made by older versions of this tool (.name, .released, .version files) are still read.
function _changelogsh_release_field {
  local dir="$1" key="$2" value=""
  if [ -f "$dir/.release" ]; then
    value=$(grep "^$key=" "$dir/.release" | head -1 | cut -d= -f2-)
  fi
  if [ -z "$value" ]; then
    case "$key" in
      name) value=$(cat "$dir/.name" 2>/dev/null) ;;
      released) value=$(cat "$dir/.released" 2>/dev/null) ;;
      version) value=$(cat "$dir/.version" 2>/dev/null) ;;
    esac
  fi
  echo "$value"
}
