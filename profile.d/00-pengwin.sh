# enable external x display
export DISPLAY=:0

# enable external libgl
export LIBGL_ALWAYS_INDIRECT=1

# speed up some GUI apps like gedit
export NO_AT_BRIDGE=1

# Fix 'clear' scrolling issues
alias clear='clear -x'

# Custom aliases
alias ll='ls -al'

# Execute on user's shell first-run
if [ ! -f "${HOME}/.firstrun" ]; then
  echo "Welcome to Pengwin. Type 'pengwin-setup' to run the setup tool. You will only see this message on the first run"
  touch "${HOME}/.firstrun"
fi

function create_winhome_link() {

  # Create a symbolic link to the windows home
  local wHomeWinPath=$(cmd.exe /c 'echo %HOMEDRIVE%%HOMEPATH%' 2>&1 | tr -d '\r')
  export WIN_HOME=$(wslpath -u "${wHomeWinPath}")

  local win_home_lnk=${HOME}/winhome
  if [ ! -e "${win_home_lnk}" ] ; then
    ln -s -f "${WIN_HOME}" "${win_home_lnk}"
  fi

}

create_winhome_link
