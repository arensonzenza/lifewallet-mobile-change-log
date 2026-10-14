#!/bin/bash

function _changelogsh_init {
  if [ ! -d 'changelog' ]; then
    mkdir 'changelog'
  fi

  if [ ! -d 'changelog/unreleased' ]; then
    mkdir 'changelog/unreleased'
  fi
}
