#!/usr/bin/env bash

set -e

INTERACTIVE=${INTERACTIVE:-"yes"}
BUILD_IMAGE=${BUILD_IMAGE:-"no"}
COM=$@
PORTS=${PORTS:-"8002-8010"}
export PORTS=${PORTS:-"8002-8010"}
CONTAINER_PORTS=${PORTS}
export CONTAINER_PORTS=${PORTS}
FOLDER_NAME=${PWD##*/}
PROJECT_NAME=${FOLDER_NAME}
export FOLDER_NAME=${PWD##*/}
if [ "${INTERACTIVE}" = "yes" ]; then
  INTERACTIVE="i"
else
  INTERACTIVE=""
fi

if [ "${COM}" != "b" ]; then
  PORTS="8002-8010"
  export PORTS="8002-8010"
  CONTAINER_PORTS="8001"
  export CONTAINER_PORTS="8001"
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
#printf "Running in ${WS_CWD}\n"
#printf "Use PUID ${PUID} and PGID ${PGID}\n"

function finish {
  if [ "${COM}" = "b" ] || [ "${COM}" = "bb" ]; then
    WS_PWD=${WS_PWD:-"${HOME}/.docker-workspace/src/docker-workspace"}
    cd ${WS_PWD}-${PROJECT_NAME}
    echo $WS_PWD > ~/.docker-workspace/debug.log
    docker-compose -f .docker-compose-${PROJECT_NAME}.yml -f .docker-compose-dev-${PROJECT_NAME}.yml down -v >> ~/.docker-workspace/debug.log
    docker-sync clean -c .docker-sync-${PROJECT_NAME}.yml >> ~/.docker-workspace/debug.log
    rm -rf .docker-sync-${PROJECT_NAME}.yml .docker-compose-${PROJECT_NAME}.yml .docker-compose-dev-${PROJECT_NAME}.yml
    cd ${WS_PWD}
    rm -rf ${WS_PWD}-${PROJECT_NAME}
  else
    docker rm -f ${PROJECT_NAME}
  fi
}

trap finish 1 2 3 6 15


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
  docker pull phusion/baseimage:0.11
  bash -c "$(curl https://raw.githubusercontent.com/travis-south/docker-workspace/master/install?no_cache=$RANDOM)"
  exit 0
fi

#CTR_COMMAND=${COM}
#export CTR_COMMAND=${COM}
if [ "${BUILD_IMAGE}" = "yes" ] 
then
  docker-compose build
  docker-sync-stack clean
fi

if [ "${COM}" = "b" ] || [ "${COM}" = "bb" ]; then
  WS_PWD=${WS_PWD:-"${HOME}/.docker-workspace/src/docker-workspace"}
  cp -pR ${WS_PWD} ${WS_PWD}-${PROJECT_NAME}
  cd ${WS_PWD}-${PROJECT_NAME}
  sed "s/native-osx/native-osx-${PROJECT_NAME}/g" docker-sync.yml > .docker-sync-${PROJECT_NAME}.yml
  sed "s/native-osx/native-osx-${PROJECT_NAME}/g" docker-compose.yml > .docker-compose-${PROJECT_NAME}.yml
  sed "s/native-osx/native-osx-${PROJECT_NAME}/g" docker-compose-dev.yml > .docker-compose-dev-${PROJECT_NAME}.yml
  docker-sync start -c .docker-sync-${PROJECT_NAME}.yml
  printf "Waiting for volume..."
  until docker volume ls | grep appcode-native-osx-${PROJECT_NAME}-sync
  do
    printf "."
    sleep 1
  done
  docker-compose -f .docker-compose-${PROJECT_NAME}.yml -f .docker-compose-dev-${PROJECT_NAME}.yml up -d
  printf "Processing..."
  until docker-compose -f .docker-compose-${PROJECT_NAME}.yml -f .docker-compose-dev-${PROJECT_NAME}.yml exec app-native-osx-${PROJECT_NAME} /sbin/setuser daker zsh -l 2>/dev/null
  do
    printf "."
    sleep 5
  done
  docker-compose -f .docker-compose-${PROJECT_NAME}.yml -f .docker-compose-dev-${PROJECT_NAME}.yml down -v
  docker-sync clean -c .docker-sync-${PROJECT_NAME}.yml
  rm -rf .docker-sync-${PROJECT_NAME}.yml .docker-compose-${PROJECT_NAME}.yml .docker-compose-dev-${PROJECT_NAME}.yml
  cd ${WS_PWD}
  rm -rf ${WS_PWD}-${PROJECT_NAME}
else
  docker run --rm -t${INTERACTIVE} \
    -v $HOME/.ssh:/home/daker/.ssh \
    -v $HOME/.docker-workspace:/home/daker/.docker-workspace \
    -v $HOME/.oh-my-zsh:/home/daker/.oh-my-zsh \
    -v $HOME/.zshrc:/home/daker/.zshrc \
    -v $HOME/.gitconfig:/home/daker/.gitconfig \
    -v $(pwd):$(pwd)${VOLUME_OPTIONS} \
    -w $(pwd) \
    $docker_sock_volume \
    --env PGID=$(id -g) --env PUID=$(id -u) \
    -p 0.0.0.0:${PORTS}:8001 \
    --name ${PROJECT_NAME} \
    travissouth/workspace:$(id -u) ${COM}
fi
