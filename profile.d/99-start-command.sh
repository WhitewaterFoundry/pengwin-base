#!/bin/sh
# bashsupport disable=BP5007

if [ -z "${PENGWIN_COMMAND}" ]; then
  return
fi
set -x
echo "${PENGWIN_COMMAND}"

saved_param="${PENGWIN_COMMAND}"
unset PENGWIN_COMMAND
set +x
if [ -n "${saved_param}" ]; then
  eval ${saved_param}

  unset saved_param
fi
