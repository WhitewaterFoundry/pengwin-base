#
# Regular cron jobs for the wlinux-base package
#
0 4	* * *	root	[ -x /usr/bin/wlinux-base_maintenance ] && /usr/bin/wlinux-base_maintenance
