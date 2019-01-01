# Example watch control file for uscan
# Rename this file to "watch" and then you can run the "uscan" command
# to check for upstream updates and more.
# See uscan(1) for format

# Compulsory line, this is a version 4 file
version=4

# PGP signature mangle, so foo.tar.gz has foo.tar.gz.sig
#opts="pgpsigurlmangle=s%$%.sig%"

# HTTP site (basic)
#http://example.com/downloads.html \
#  files/wlinux-base-([\d\.]+)\.tar\.gz debian uupdate

# Uncomment to examine an FTP server
#ftp://ftp.example.com/pub/wlinux-base-(.*)\.tar\.gz debian uupdate

# SourceForge hosted projects
# http://sf.net/wlinux-base/ wlinux-base-(.*)\.tar\.gz debian uupdate

# GitHub hosted projects
#opts="filenamemangle=s%(?:.*?)?v?(\d[\d.]*)\.tar\.gz%<project>-$1.tar.gz%" \
#   https://github.com/<user>/wlinux-base/tags \
#   (?:.*?/)?v?(\d[\d.]*)\.tar\.gz debian uupdate

# PyPI
# https://pypi.debian.net/wlinux-base/wlinux-base-(.+)\.(?:zip|tgz|tbz|txz|(?:tar\.(?:gz|bz2|xz)))

# Direct Git
# opts="mode=git" http://git.example.com/wlinux-base.git \
#   refs/tags/v([\d\.]+) debian uupdate




# Uncomment to find new files on GooglePages
# http://example.googlepages.com/foo.html wlinux-base-(.*)\.tar\.gz
