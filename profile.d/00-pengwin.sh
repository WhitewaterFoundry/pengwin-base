# check whether it is WSL1 for WSL2 by using gcc version kernel built with
if[ $(grep -oE 'gcc version ([0-9]+)' /proc/version | awk '{print $3}') -gt 5 ]; then
  # enable external x display for WSL 2
  export DISPLAY=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2; exit;}'):0.0
else
  # enable external x display for WSL 1
  export DISPLAY=:0
fi

# enable external libgl
export LIBGL_ALWAYS_INDIRECT=1

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

fi
