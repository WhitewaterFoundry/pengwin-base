#!/bin/sh
# bashsupport disable=BP5007

hushlogin_not_enabled() {
  [ ! -e "${hushlogin_file}" ]
}

motd_shown_today() {
  find "${motd_shown_file}" -newermt 'today  0:00' 2>/dev/null | grep -q -m 1 ''
}

motd_show_always() {
  [ -e "${motd_show_always_file}" ]
}

main() {
  # runs the scripts on /etc/update-motd.d
  motd_shown_file="$HOME/.motd_shown"
  hushlogin_file="$HOME/.hushlogin"
  motd_show_always_file="$HOME/.motd_show_always"

  if motd_show_always || (hushlogin_not_enabled && ! motd_shown_today); then
    run-parts --lsbsysinit /etc/update-motd.d
    touch "${motd_shown_file}"
    printf "\n"
    printf "This message is shown once a day. To disable it you can create the %s file" "${hushlogin_file}"
    printf "\n\n"
  fi

  unset motd_shown_file
  unset hushlogin_file
  unset motd_show_always_file
}

main "$@"
