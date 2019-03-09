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
    echo "Welcome to WLinux. Type 'wlinux-setup' to run the setup tool. You will only see this message on first run"
    touch "${HOME}/.firstrun"
fi
