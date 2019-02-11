# WSL
IS_WSL=`grep -i microsoft /proc/version`
if test "$IS_WSL" = ""; then
  if [ "`id -u`" -eq 0 ]; then
    PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
  else
    PATH="/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games"
  fi
fi
export PATH

# enable external x display
export DISPLAY=:0

# enable external libgl
export LIBGL_ALWAYS_INDIRECT=1

# speed up some GUI apps like gedit
export NO_AT_BRIDGE=1

# Execute on user's shell first-run
if [ ! -f "${HOME}/.firstrun" ]; then
    echo "Welcome to WLinux. Type 'wlinux-setup' to run the setup tool. You will only see this message on first run"
    touch "${HOME}/.firstrun"
fi
