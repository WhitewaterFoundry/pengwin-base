#!/bin/fish

# check whether it is WSL1 for WSL2
if test -n "$WSL_INTEROP"
  #Export an enviroment variable for helping other processes
  set --export WSL2 1

  if test -z "$DISPLAY"
    # enable external x display for WSL 2

    set ipconfig_exec (wslpath "C:\\Windows\\System32\\ipconfig.exe")
    if command -q ipconfig.exe
      set ipconfig_exec (command -s ipconfig.exe)
    end

    set wsl2_d_tmp (eval $ipconfig_exec | grep -n -m 1 "Default Gateway.*: [0-9a-z]" | cut -d : -f 1)
    if test -n "$wsl2_d_tmp"
      set first_line (expr $wsl2_d_tmp - 4)
      set wsl2_d_tmp (eval $ipconfig_exec | sed $first_line,$wsl2_d_tmp!d | grep IPv4 | cut -d : -f 2 | sed -e "s|\s||g" -e "s|\r||g")
      set --export DISPLAY "$wsl2_d_tmp:0"
      set -e first_line
    else
      set --export DISPLAY (cat /etc/resolv.conf | grep nameserver | awk '{print $2}'):0
    end

    set -e wsl2_d_tmp
    set -e ipconfig_exec
  end
else
  # enable external x display for WSL 1
  set --export DISPLAY "localhost:0"
end

if test -n "$XRDP_SESSION"
  set -e DISPLAY
end

# enable external libgl if mesa is not installed
if command -q glxinfo
  set -e LIBGL_ALWAYS_INDIRECT
else
  set --export LIBGL_ALWAYS_INDIRECT 1
end

# speed up some GUI apps like gedit
set --export NO_AT_BRIDGE 1

# Fix 'clear' scrolling issues
alias clear='clear -x'

# Custom aliases
alias ll='ls -al'

# Check if we have Windows Path
if command -q cmd.exe ; and status --is-login

  # Execute on user's shell first-run
  if test ! -f "$HOME/.firstrun"
    echo "Welcome to Pengwin. Type 'pengwin-setup' to run the setup tool. You will only see this message on the first run."
    touch "$HOME/.firstrun"
  end

  if not wslpath 'C:\\' >/dev/null 2>&1
    alias wslpath=legacy_wslupath
  end

  # Create a symbolic link to the windows home
  set wHomeWinPath (cmd.exe /c 'echo %HOMEDRIVE%%HOMEPATH%' 2>/dev/null | tr -d '\r')
  set --export WIN_HOME (wslpath -u $wHomeWinPath)

  set win_home_lnk "$HOME/winhome"
  if test ! -e "$win_home_lnk"
    ln -s -f "$WIN_HOME" "$win_home_lnk"
  end

  set -e win_home_lnk
end
