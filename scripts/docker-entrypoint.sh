#!/bin/bash

function exitColumnStore {
  /usr/bin/monit unmonitor all
  /usr/bin/columnstore-stop
  /usr/bin/monit quit
}

rm -f /var/run/syslogd.pid
rsyslogd

trap exitColumnStore SIGTERM

exec "$@" &

wait
