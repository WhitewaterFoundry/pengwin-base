#!/bin/sh

# Alias for WSL1 compatibility - run casdial binary with explicit ld-linux loader
# Only apply the workaround if WSL2 is not set (i.e., we're in WSL1)
# This allows users who switch to WSL2 to run casdial directly
if [ -z "${WSL2}" ]; then
  alias casdial="/lib64/ld-linux-x86-64.so.2 /usr/bin/casdial"
fi