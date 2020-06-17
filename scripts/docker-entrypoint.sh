#!/bin/bash

function exitColumnStore {
  monit quit
  columnstore stop
}

rsyslogd

trap exitColumnStore SIGTERM

exec "$@" &

wait
