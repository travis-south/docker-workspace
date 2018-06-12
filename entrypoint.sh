#!/usr/bin/env bash

mkdir -p /home/daker/.docker-workspace
chown -R daker:daker /home/daker/.docker-workspace

exec /sbin/setuser daker "$@"
