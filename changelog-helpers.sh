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
