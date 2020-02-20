#!/bin/bash

function exitColumnStore {
  /usr/bin/monit quit
  /usr/bin/columnstore stop
}

trap exitColumnStore SIGTERM

exec "$@" &

wait
