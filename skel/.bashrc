## Template user .bashrc

# Add location of our custom wlinux-setup script to path
export PATH="$PATH:/opt/bin"

# Check for existence of our custom virtual language environment
# install location, if so, source the profile
if [[ -f "/home/.envs/envrc" ]] ; then
    source "/home/.envs/envrc"
fi