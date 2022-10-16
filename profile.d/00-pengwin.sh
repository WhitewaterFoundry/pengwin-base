#!/bin/sh
# bashsupport disable=BP5007

save_environment() {
  {
    echo "PATH='$PATH'"
    echo "WSL_DISTRO_NAME='$WSL_DISTRO_NAME'"
    echo "WSL_INTEROP='$WSL_INTEROP'"
    echo "WSL_SYSTEMD_EXECUTION_ARGS='$WSL_SYSTEMD_EXECUTION_ARGS'"
    echo "PULSE_SERVER='$PULSE_SERVER'"
    echo "PENGWIN_REMOTE_DESKTOP='$PENGWIN_REMOTE_DESKTOP'"
  } >"${systemd_saved_environment}"
}

check_and_start_systemd() {

  #WSL1 not supported
  if [ -z "${WSL_INTEROP}" ]; then
    return
  fi

  # SystemD is running, then we're done
  systemd_pid="$(ps -C systemd -o pid= | head -n1)"
  if [ -n "$systemd_pid" ] && [ "$systemd_pid" -eq 1 ]; then
    return
  fi

  # check if SystemD is enabled in wsl.conf but not running
  # shellcheck disable=SC2155
  systemd_enabled=$(grep -c -E "^systemd.*=.*true$" "/etc/wsl.conf")
  if [ "${systemd_enabled}" -eq 1 ]; then
    save_environment

    sudo /usr/local/bin/start-systemd

    exit 0
  fi
}

setup_interop() {
  # shellcheck disable=SC2155,SC2012
  export WSL_INTEROP="$(ls -U /run/WSL/*_interop | tail -1)"
}

setup_display_via_resolv() {
  wsl2_d_tmp="$(grep </etc/resolv.conf nameserver | awk '{print $2}')"
  export DISPLAY="${wsl2_d_tmp}":0

  # check if the type is changed
  sudo /usr/local/bin/wsl_change_checker 1
  #Export an environment variable for helping other processes
  export WSL2=1

  unset wsl2_d_tmp
}

setup_display() {

  if [ -n "${XRDP_SESSION}" ] ; then
    if [ -f "${systemd_saved_environment}" ]; then
      set -a
      # shellcheck disable=SC1090
      . "${systemd_saved_environment}"
      set +a
    fi

    if [ -n "${WSL_INTEROP}" ]; then
      export WSL2=1

      setup_interop
    fi

    pulseaudio --start >/dev/null 2>&1
    return
  fi

  if [ -n "${SSH_CONNECTION}" ]; then
    return
  fi

  # WSL2 Environment variable meaning:
  # WSL2=0: WSL1
  # WSL2=1: WSL2 (Type 1)
  # WSL2=2: WSL2 (Type 2)
  # WSL2=3: WSL2 (Type 3)
  if [ -n "${WSL_INTEROP}" ]; then
    if [ -n "${DISPLAY}" ]; then #WSLg
      # check if the type is changed
      sudo /usr/local/bin/wsl_change_checker 3
      #Export an environment variable for helping other processes
      export WSL2=3

      if socket_index="$(sudo /usr/local/bin/check_x11_socket "$DISPLAY")"; then
        export DISPLAY=":${socket_index}"
      fi

      return
    fi

    if [ -f "${HOME}/.config/pengwin/display_ip_from_dns" ]; then
      setup_display_via_resolv
      return
    fi

    # enable external x display for WSL 2
    if route_exec_path=$(command -v route.exe 2>/dev/null); then
      route_exec="${route_exec_path}"
    else
      route_exec=$(wslpath 'C:\Windows\system32\route.exe')
    fi

    wsl2_d_tmp="$(eval "$route_exec print 2> /dev/null" | grep 0.0.0.0 | head -1 | awk '{print $4}')"

    if [ -n "${wsl2_d_tmp}" ]; then
      export DISPLAY="${wsl2_d_tmp}":0

      # check if the type is changed
      sudo /usr/local/bin/wsl_change_checker 2
      #Export an environment variable for helping other processes
      export WSL2=2

    else
      setup_display_via_resolv
    fi

    unset route_exec
    unset wsl2_d_tmp

  else

    # enable external x display for WSL 1
    export DISPLAY=localhost:0

    # check if we have wsl.exe in path
    sudo /usr/local/bin/wsl_change_checker 0

    # Export an environment variable for helping other processes
    unset WSL2

  fi
}

main() {
  # Only the default WSL user should run this script
  if ! (id -Gn | grep -c "adm.*sudo\|sudo.*adm" >/dev/null); then
    return
  fi

  systemd_saved_environment="$HOME/.systemd.env"

  check_and_start_systemd
  setup_display

  # enable external libgl if mesa is not installed
  if (command -v glxinfo >/dev/null 2>&1); then
    unset LIBGL_ALWAYS_INDIRECT
    sudo /usr/local/bin/libgl-change-checker 0
  else
    export LIBGL_ALWAYS_INDIRECT=1
    sudo /usr/local/bin/libgl-change-checker 1
  fi

  # speed up some GUI apps like gedit
  export NO_AT_BRIDGE=1

  # Fix 'clear' scrolling issues
  alias clear='clear -x'

  # Custom aliases
  alias ll='ls -al'
  alias winget='powershell.exe winget'
  alias wsl='wsl.exe'

  # Check if we have Windows Path
  if (command -v cmd.exe >/dev/null); then

    save_environment

    # Execute on user's shell first-run
    if [ ! -f "${HOME}/.firstrun" ]; then
      echo "Welcome to Pengwin. Type 'pengwin-setup' to run the setup tool. You will only see this message on the first run."
      touch "${HOME}/.firstrun"
    fi

    # shellcheck disable=SC1003
    if (! wslpath 'C:\' >/dev/null 2>&1); then
      # shellcheck disable=SC2262
      alias wslpath=legacy_wslupath
    fi

    # Create a symbolic link to the windows home

    # Here have a issue: %HOMEDRIVE% might be using a custom set location
    # moving cmd to where Windows is installed might help: %SYSTEMDRIVE%
    wHomeWinPath=$(cmd-exe /c 'cd %SYSTEMDRIVE%\ && echo %HOMEDRIVE%%HOMEPATH%' 2>/dev/null | tr -d '\r')

    if [ ${#wHomeWinPath} -le 3 ]; then #wHomeWinPath contains something like H:\
      wHomeWinPath=$(cmd-exe /c 'cd %SYSTEMDRIVE%\ && echo %USERPROFILE%' 2>/dev/null | tr -d '\r')
    fi

    # shellcheck disable=SC2155
    export WIN_HOME="$(wslpath -u "${wHomeWinPath}")"

    win_home_lnk=${HOME}/winhome
    if [ ! -e "${win_home_lnk}" ]; then
      ln -s -f "${WIN_HOME}" "${win_home_lnk}" >/dev/null 2>&1
    fi

    unset win_home_lnk
    unset systemd_saved_environment
  fi
}

main
