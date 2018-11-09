#!/usr/bin/env bash

set -e

INTERACTIVE=${INTERACTIVE:-"yes"}
COM=$@
PORTS="8001-8010"
export PORTS="8001-8010"
if [ "${INTERACTIVE}" = "yes" ]; then
  INTERACTIVE="i"
else
  INTERACTIVE=""
fi

if [ "${COM}" = "b" ]; then
  COM="bash -l"
  PORTS="8001"
  export PORTS="8001"
fi

if [ "${COM}" = "bb" ]; then
  COM="bash -l"
  PORTS="8002-8010"
  export PORTS="8002-8010"
fi

VOLUME_OPTIONS=""

case "$(uname)" in
  Darwin)
    VOLUME_OPTIONS=":delegated"
    ;;
esac

command -v docker >/dev/null 2>&1 || { echo >&2 "I require docker but it's not installed.  Aborting."; exit 1; }
command -v docker-compose >/dev/null 2>&1 || { echo >&2 "I require docker-compose but it's not installed.  Aborting."; exit 1; }

WS_CWD=$PWD
export WS_CWD=$PWD
PGID=$(id -g)
PUID=$(id -u)
export PGID=$(id -g)
export PUID=$(id -u)
printf "Running in ${WS_CWD}\n"
printf "Use PUID ${PUID} and PGID ${PGID}\n"

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

CTR_COMMAND=${COM}
export CTR_COMMAND=${COM}
cd ${WS_PWD:-"${HOME}/.docker-workspace/src/docker-workspace"}
docker-sync-stack clean
docker-sync-stack start &

until docker-compose exec app-native-osx /sbin/setuser daker bash -l
do
  printf "Try again...\n"
  sleep 5
done
