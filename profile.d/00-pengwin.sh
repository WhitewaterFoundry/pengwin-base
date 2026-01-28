#!/bin/sh
# bashsupport disable=BP5007

save_environment() {
  {
    echo "PATH='$PATH'"
    echo "WSL_DISTRO_NAME='$WSL_DISTRO_NAME'"
    echo "WSL_INTEROP='$WSL_INTEROP'"
    echo "WSL_SYSTEMD_EXECUTION_ARGS='$WSL_SYSTEMD_EXECUTION_ARGS'"
    echo "PULSE_SERVER='$PULSE_SERVER'"
    echo "WAYLAND_DISPLAY='$WAYLAND_DISPLAY'"
    echo "PENGWIN_COMMAND='$PENGWIN_COMMAND'"
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
  wsl2_d_tmp="$(ip route | grep default | awk '{print $3; exit;}')"
  export DISPLAY="${wsl2_d_tmp}":0

  # check if the type is changed
  sudo /usr/local/bin/wsl_change_checker 1
  #Export an environment variable for helping other processes
  export WSL2=1

  unset wsl2_d_tmp
}

setup_display() {
  if [ -n "${XRDP_SESSION}" ]; then
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

    unset WAYLAND_DISPLAY
    if [ -n "$SYSTEMD_PID" ]; then
      rm -f /run/user/"$(id -u)"/wayland* 2>/dev/null
    fi

    if [ -z "${PULSE_SERVER}" ]; then
      pulseaudio --enable-memfd=FALSE --disable-shm=TRUE --log-target=syslog --start >/dev/null 2>&1
    fi

    return
  fi

  if [ -n "${SSH_CONNECTION}" ]; then
    return
  fi

  # WSL2 Environment variable meaning:
  # WSL2=0: WSL1
  # WSL2=1: WSL2 (Type 1) using the IP of resolv.conf
  # WSL2=2: WSL2 (Type 2) using the IP of the gateway (host IP)
  # WSL2=3: WSL2 (Type 3) using the DISPLAY variable already set WSLg?
  if [ -n "${WSL_INTEROP}" ]; then
    #Export an environment variable for helping other processes
    export WSL2=1

    if [ -n "${DISPLAY}" ] && [ ! -f "${HOME}/.config/pengwin/disable_wslg" ]; then #WSLg
      # check if the type is changed
      sudo /usr/local/bin/wsl_change_checker 3
      #Export an environment variable for helping other processes
      export WSL2=3

      if socket_index="$(sudo /usr/local/bin/check_x11_socket "$DISPLAY")"; then
        export DISPLAY=":${socket_index}"
      fi

      uid="$(id -u)"

      user_path="/run/user/${uid}"
      if [ ! -d "${user_path}" ]; then
        sudo /usr/local/bin/create_userpath "${uid}" 2>/dev/null
      fi

      if [ -z "$SYSTEMD_PID" ]; then
        export XDG_RUNTIME_DIR="${user_path}"
      fi

      wslg_runtime_dir="/mnt/wslg/runtime-dir"

      ln -fs "${wslg_runtime_dir}"/wayland-0 "${user_path}"/ 2>/dev/null
      ln -fs "${wslg_runtime_dir}"/wayland-0.lock "${user_path}"/ 2>/dev/null

      pulse_path="${user_path}/pulse"
      wslg_pulse_dir="${wslg_runtime_dir}"/pulse

      if [ ! -d "${pulse_path}" ]; then
        mkdir -p "${pulse_path}" 2>/dev/null

        ln -fs "${wslg_pulse_dir}"/native "${pulse_path}"/ 2>/dev/null
        ln -fs "${wslg_pulse_dir}"/pid "${pulse_path}"/ 2>/dev/null

      elif [ -S "${pulse_path}/native" ]; then
        # Handle stale socket: remove it and recreate as symlink to WSLg pulse
        rm -f "${pulse_path}/native" 2>/dev/null
        ln -fs "${wslg_pulse_dir}"/native "${pulse_path}"/ 2>/dev/null
      fi

      unset user_path
      unset wslg_runtime_dir
      unset wslg_pulse_dir
      unset pulse_path
      unset uid

      return
    fi

    if [ -f "${HOME}/.config/pengwin/display_ip_from_dns" ]; then
      setup_display_via_resolv
      return
    fi

    # enable external x display for WSL 2
    route_exec=$(wslpath 'C:\Windows\system32\route.exe')

    if route_exec_path=$(command -v route.exe 2>/dev/null); then
      route_exec="${route_exec_path}"
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

    unset wsl2_d_tmp
    unset route_exec
  else
    # enable external x display for WSL 1
    export DISPLAY=localhost:0

    # check if we have wsl.exe in path
    sudo /usr/local/bin/wsl_change_checker 0

    # Export an environment variable for helping other processes
    unset WSL2
  fi
}

setup_dbus() {
  # if dbus-launch is installed, then load it
  if ! (command -v dbus-launch >/dev/null); then
    return
  fi

  # Enabled via systemd
  if [ -n "${DBUS_SESSION_BUS_ADDRESS}" ]; then
    return
  fi

  # Use a per-user directory for storing the D-Bus environment
  dbus_env_dir="${XDG_RUNTIME_DIR:-${HOME}/.cache}"
  mkdir -p "${dbus_env_dir}" 2>/dev/null || true

  dbus_pid="$(pidof -s dbus-daemon)"

  if [ -z "${dbus_pid}" ]; then
    dbus_env="$(timeout 2s dbus-launch --auto-syntax)" || return

    # Extract and export only the expected variables from dbus-launch output
    DBUS_SESSION_BUS_ADDRESS="$(printf '%s\n' "${dbus_env}" | sed -n "s/^DBUS_SESSION_BUS_ADDRESS='\(.*\)';\$/\1/p")"
    DBUS_SESSION_BUS_PID="$(printf '%s\n' "${dbus_env}" | sed -n "s/^DBUS_SESSION_BUS_PID=\([0-9][0-9]*\);$/\1/p")"

    if [ -n "${DBUS_SESSION_BUS_ADDRESS}" ] && [ -n "${DBUS_SESSION_BUS_PID}" ]; then
      export DBUS_SESSION_BUS_ADDRESS
      export DBUS_SESSION_BUS_PID

      dbus_env_file="${dbus_env_dir}/dbus_env_${DBUS_SESSION_BUS_PID}"
      {
        echo "DBUS_SESSION_BUS_ADDRESS='${DBUS_SESSION_BUS_ADDRESS}'"
        echo "DBUS_SESSION_BUS_PID='${DBUS_SESSION_BUS_PID}'"
      } >"${dbus_env_file}"
      chmod 600 "${dbus_env_file}" 2>/dev/null || true
    fi

    unset dbus_env
  else
    # Reuse existing dbus session
    dbus_env_file="${dbus_env_dir}/dbus_env_${dbus_pid}"
    if [ -f "${dbus_env_file}" ]; then
      DBUS_SESSION_BUS_ADDRESS="$(sed -n "s/^DBUS_SESSION_BUS_ADDRESS='\(.*\)'\$/\1/p" "${dbus_env_file}")"
      DBUS_SESSION_BUS_PID="$(sed -n "s/^DBUS_SESSION_BUS_PID='\([0-9][0-9]*\)'\$/\1/p" "${dbus_env_file}")"
      if [ -n "${DBUS_SESSION_BUS_ADDRESS}" ] && [ -n "${DBUS_SESSION_BUS_PID}" ]; then
        export DBUS_SESSION_BUS_ADDRESS
        export DBUS_SESSION_BUS_PID
      fi
    fi
  fi

  unset dbus_pid
  unset dbus_env_file
  unset dbus_env_dir
}

main() {
  # Only the default WSL user should run this script
  if ! (id -Gn | grep -c "adm.*sudo\|sudo.*adm" >/dev/null); then
    return
  fi

  systemd_saved_environment="$HOME/.systemd.env"

  check_and_start_systemd
  SYSTEMD_PID="$(ps -C systemd -o pid= | head -n1)"
  setup_display

  if [ -z "$SYSTEMD_PID" ]; then
    setup_dbus
  fi

  # speed up some GUI apps like gedit
  export NO_AT_BRIDGE=1

  # Fix 'clear' scrolling issues
  alias clear='clear -x'

  # Custom aliases
  alias ll='ls -al'
  alias winget='powershell.exe winget'
  alias wsl='wsl.exe'

  if [ -n "${WSL2}" ]; then
    # Setup video acceleration
    export VDPAU_DRIVER=d3d12
    export LIBVA_DRIVER_NAME=d3d12
    sudo /usr/local/bin/pengwin-load-vgem-module

    # Setup Gallium Direct3D 12 driver
    export GALLIUM_DRIVER=d3d12
  fi

  if [ -z "$SYSTEMD_PID" ]; then

    save_environment
  fi

  if (command -v cmd.exe >/dev/null); then
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
  fi

  # Check if we have Windows Path
  if [ -z "$WIN_HOME" ] && (command -v cmd.exe >/dev/null 2>&1); then

    # Create a symbolic link to the windows home

    # Here has an issue: %HOMEDRIVE% might be using a custom set location
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

main "$@"
