#!/usr/bin/env bash

do_install() {
  curl -L https://raw.githubusercontent.com/dockerizedrupal/crush/master/crush.sh > /usr/local/bin/crush

  chmod +x /usr/local/bin/crush

  hash drush 2> /dev/null

  if [ "${?}" -ne 0 ]; then
    ln -s /usr/local/bin/crush /usr/local/bin/drush
  fi
}

do_install
