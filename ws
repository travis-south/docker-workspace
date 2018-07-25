#!/usr/bin/env bash

set -e

command -v docker >/dev/null 2>&1 || { echo >&2 "I require docker but it's not installed.  Aborting."; exit 1; }

docker_sock_volume=""
# Check if we have docker on host
if [ -S "/var/run/docker.sock" ]; then
  docker_sock_volume="--volume=/var/run/docker.sock:/var/run/docker.sock"
fi

# Prepare ssh keys
if [ ! -d "$HOME/.ssh" ]; then
   printf ${red}"You need to setup your ssh keys first."${neutral}"\n"
   exit 1
fi

if [ "$1" = "update" ]; then
  docker pull phusion/baseimage:0.10.1
  bash <(curl https://raw.githubusercontent.com/travis-south/docker-workspace/master/install?no_cache=$RANDOM)
  exit 0
fi

docker run --rm -ti \
    -v $HOME/.ssh:/home/daker/.ssh \
    -v $HOME/.docker-workspace:/home/daker/.docker-workspace \
    -v $(pwd):$(pwd) \
    -w $(pwd) \
    $docker_sock_volume \
    --env PGID=$(id -g) --env PUID=$(id -u) \
    -p 0.0.0.0:8001-8010:8001 \
    travissouth/workspace:$(id -u) "$@"
