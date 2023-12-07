#!/usr/bin/env bash

DOCKER_IMAGE=demo-molecule:1.0.0

function _install_poetry() {
  curl -sSL https://install.python-poetry.org | python3 -
  bin_path=$HOME/.local/bin
  if [ -n "${PATH##*${bin_path}}" ] && [ -n "${PATH##*${bin_path}:*}" ]; then
      export PATH="$PATH:${bin_path}"
  fi
}

# Initialisation des variables d'environnement
function _set_vars_env() {
  # Variables d'environnement du proxy
  if [ -f .proxy ]; then source .proxy; fi
  # ID/GID du user connecté
  USER_ID=$(id -u)
  USER_GID=$(id -g)
  # GID du group docker
  DOCKER_GID=$(getent group docker| cut -d: -f3)
  export USER_ID
  export USER_GID
  export DOCKER_GID
}

# Construction de l'image docker demo-molecule
function _build_configuration_docker() {
  command=""
  image_exist=$(docker images "$DOCKER_IMAGE" --format "{{.ID}}")
  build_args="--build-arg http_proxy=\"${http_proxy}\" \
     --build-arg https_proxy=\"${https_proxy}\" \
     --build-arg no_proxy=\"${no_proxy}\" \
     --build-arg USER_ID=\"${USER_ID}\" \
     --build-arg USER_GID=\"${USER_GID}\" \
     --build-arg DOCKER_GID=\"${DOCKER_GID}\""
  if [ "$1" = "--force" ]; then
    if [ -n "$image_exist" ]; then docker image rm "$DOCKER_IMAGE"; fi
    command="DOCKER_BUILDKIT=1 \
    docker build -f Dockerfile --no-cache --target=runtime $build_args -t=$DOCKER_IMAGE ."
  else
    if [ -z "$image_exist" ]; then
      command="DOCKER_BUILDKIT=1 \
      docker build -f Dockerfile --target=runtime $build_args -t=$DOCKER_IMAGE ."
    fi
  fi
  if [ -n "$command" ]; then eval "$command"; fi
}

# Installation de l'environnement ansible
function build_env() {
  echo "===> Installation de l'environnement"
  # Check poetry.lock
  if [ ! -f poetry.lock ]; then
    if ! command -v poetry &> /dev/null; then
      _install_poetry
    fi
    poetry install
  fi
  # Variables d'environnement
  _set_vars_env
  # Construction de l'image docker python avec ansible et molecule
  _build_configuration_docker "$1"
}

# Execution d'une commande dans le container configuration
function run_env() {
  exec_command="/bin/bash"
  if [ -n "$1" ] && [ ! "$1" = "--force" ]; then
    exec_command=$*
  fi
  if [ "$(docker ps -a | grep -c configuration)" -gt 0 ]; then
    docker exec -it configuration bash
  else
    command="docker run --rm -it --name demo-molecule --privileged \
      -v /var/run/docker.sock:/var/run/docker.sock:rw \
      -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
      -w=/app/demo-molecule \
      -v ${PWD}:/app/demo-molecule \
      -e ENV=$ENV \
      $DOCKER_IMAGE $exec_command"
    echo "$command"
    eval "$command"
  fi
}

if build_env "$*"; then
  run_env "$*";
fi
