#!/bin/sh

# Alias for WSL1 compatibility - run binaries with explicit ld-linux loader
# Only apply the workaround if WSL2 is not set (i.e., we're in WSL1)
# This allows users who switch to WSL2 to run binaries directly
if [ -z "${WSL2}" ]; then
  # List of command paths that need the ld-linux loader
  COMMANDS="/usr/bin/casdial"

  for cmd in $COMMANDS; do
    if [ -f "$cmd" ]; then
      cmd_name=$(basename "$cmd")
      alias "$cmd_name"="/lib64/ld-linux-x86-64.so.2 $cmd"
    fi
  done
fi