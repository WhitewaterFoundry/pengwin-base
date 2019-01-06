## Template user .zshrc

# Check for existence of our custom virtual language environment
# install location, if so, source the profile
if [[ -f "/home/.envs/envrc" ]] ; then
    source "/home/.envs/envrc"
fi

# Execute on user's shell first-run
if [ ! -f "~/.firstrun" ]; then
    echo "Welcome to WLinux. Type 'wlinux-setup' to run the setup tool. You will only see this message once."
    touch ~/.firstrun
fi