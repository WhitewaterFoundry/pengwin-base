## Template user .bashrc

# Check for existence of our custom virtual language environment
# install location, if so, source the profile
if [[ -f "/home/.envs/envrc" ]] ; then
    source "/home/.envs/envrc"
fi

# Add our own + common aliases
alias ll="ls -al"
