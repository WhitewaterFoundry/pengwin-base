
# check whether it is WSL1 for WSL2
source /etc/environment

function wsl2_change_checker () {
  wsl2_type=$1; shift
  wsl2_readable_type=$1; shift
  wsl_display_cont=$1
  
  # no sudo support
  if [ ! -f /etc/sudoers.d/pengwin-wsl ]; then
    (echo "%sudo   ALL=NOPASSWD: /bin/sed, /bin/rm" | sudo EDITOR='tee -a' visudo --quiet --file=/etc/sudoers.d/pengwin-wsl) &>/dev/null
  fi

  if ( which wsl.exe >/dev/null ); then
    if [ ! $WSL2 -eq $wsl2_type ]; then
      sudo sed -i 's/^DISPLAY=.*$/DISPLAY='$wsl_display_cont'/g' /etc/environment
      sudo sed -i 's/^WSL2=.*$/WSL2='$wsl2_type'/g' /etc/environment
      echo "Detected: Switched to $wsl2_readable_type. Restart Pengwin to apply changes."
    fi
  fi

  # cleanup
  unset wsl2_type
  unset wsl2_readable_type
  unset wsl_display_cont
  sudo rm /etc/sudoers.d/pengwin-wsl
}


if [[ -n ${WSL_INTEROP} ]]; then
  # enable external x display for WSL 2

  ipconfig_exec=$(wslpath "C:\\Windows\\System32\\ipconfig.exe")
  if ( which ipconfig.exe &>/dev/null ); then
    ipconfig_exec=$(which ipconfig.exe)
  fi

  if ( eval "$ipconfig_exec" | grep -n -m 1 "Default Gateway.*: [0-9a-z]" | cut -d : -f 1 ) >/dev/null; then
    wsl2_d_tmp="$(eval "$ipconfig_exec" | grep -n -m 1 "Default Gateway.*: [0-9a-z]" | cut -d : -f 1)"
    wsl2_d_tmp="$(eval "$ipconfig_exec" | sed $(expr $wsl2_d_tmp - 4)','$(expr $wsl2_d_tmp + 0)'!d' | grep IPv4 | cut -d : -f 2 | sed -e "s|\s||g" -e "s|\r||g")"
    export DISPLAY=${wsl2_d_tmp}:0.0

    # check if we have wsl.exe in path
    wsl2_change_checker 1 "WSL2 (Type 2)" "${wsl2_d_tmp}:0\.0"

    #Export an enviroment variable for helping other processes
    export WSL2=1

  else
    export DISPLAY=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'):0

    # check if we have wsl.exe in path
    wsl2_change_checker 0 "WSL2 (Type 1)" "$DISPLAY"

    #Export an enviroment variable for helping other processes
    unset WSL2
  fi



  unset wsl2_d_tmp
  unset ipconfig_exec
else

  # enable external x display for WSL 1
  export DISPLAY=:0

  # check if we have wsl.exe in path
  wsl2_change_checker 2 "WSL1" ":0"

  # Export an enviroment variable for helping other processes
  export WSL2=2

fi



# enable external libgl if mesa is not installed
if ( which glxinfo > /dev/null 2>&1 ); then
  unset LIBGL_ALWAYS_INDIRECT
else
  export LIBGL_ALWAYS_INDIRECT=1
fi

# speed up some GUI apps like gedit
export NO_AT_BRIDGE=1

# Fix 'clear' scrolling issues
alias clear='clear -x'

# Custom aliases
alias ll='ls -al'

# Check if we have Windows Path
if ( which cmd.exe >/dev/null ); then

  # Execute on user's shell first-run
  if [ ! -f "${HOME}/.firstrun" ]; then
    echo "Welcome to Pengwin. Type 'pengwin-setup' to run the setup tool. You will only see this message on the first run."
    touch "${HOME}/.firstrun"
  fi

  if ( ! wslpath 'C:\' > /dev/null 2>&1 ); then
    alias wslpath=legacy_wslupath
  fi

  # Create a symbolic link to the windows home
  wHomeWinPath=$(cmd-exe /c 'echo %HOMEDRIVE%%HOMEPATH%' | tr -d '\r')
  export WIN_HOME=$(wslpath -u "${wHomeWinPath}")

  win_home_lnk=${HOME}/winhome
  if [ ! -e "${win_home_lnk}" ] ; then
    ln -s -f "${WIN_HOME}" "${win_home_lnk}"
  fi

  unset win_home_lnk

fi

