#!/usr/bin/env bash

DOCKER_IMAGE_PROJECT=demo-molecule:1.0.0
DOCKER_IMAGE_MOLECULE=molecule-alpine:1.0.0
CONTAINER_NAME=demo_molecule

# Installation de Poetry
function _install_poetry() {
  curl -sSL https://install.python-poetry.org | python3 -
  bin_path=$HOME/.local/bin
  if [ -n "${PATH##*${bin_path}}" ] && [ -n "${PATH##*${bin_path}:*}" ]; then
      export PATH="$PATH:${bin_path}"
  fi
}

 # Initialisation de Poetry
_init_poetry() {
  # Check poetry.lock
  if [ ! -f poetry.lock ]; then
    if ! command -v poetry &> /dev/null; then
      _install_poetry
    fi
    poetry install
  fi
}

# Initialisation des variables d'environnement
function _set_vars_env() {
  # Variables d'environnement du proxy
  [[ -f .proxy ]] && source .proxy && export {http,https,ftp}_proxy
  # ID/GID du user connecté
  USER_ID=$(id -u)
  USER_GID=$(id -g)
  # GID du group docker
  DOCKER_GID=$(getent group docker| cut -d: -f3)
  export USER_ID
  export USER_GID
  export DOCKER_GID
}

# Générer les arguments
_build_docker_args() {
  build_args="--build-arg http_proxy=\"${http_proxy}\" \
       --build-arg https_proxy=\"${https_proxy}\" \
       --build-arg no_proxy=\"${no_proxy}\" \
       --build-arg USER_ID=\"${USER_ID}\" \
       --build-arg USER_GID=\"${USER_GID}\" \
       --build-arg DOCKER_GID=\"${DOCKER_GID}\""
}

# Construction d'une image docker
function _build_image_docker() {
  local docker_file=$1
  local image_tag=$2
  local build_args=$3
  local target=$4
  local force=${5:-0}
  local command="DOCKER_BUILDKIT=1 docker build -f $docker_file -t=$image_tag $build_args"
  [[ -n $target ]] && command+=" --target=$target"
  [[ "$force" -eq 1 ]] && docker image rm "$image_tag" 2>/dev/null && command+=" --no-cache"
  command+=" ."
  image_id=$(docker images "$image_tag" --format "{{.ID}}")
  [[ -z "$image_id" ]] && echo "$command" && eval "$command"
  return 0
}

# Construction de l'environnement docker du projet
function _build_docker_project() {
  local force=0 && [[ $1 == "--force" ]] && force=1
  _build_docker_args
  _build_image_docker "Dockerfile" "$DOCKER_IMAGE_PROJECT" "$build_args" "runtime" $force
}

# Construction de l'environnement docker de molecule
function _build_docker_molecule() {
  local force=0 && [[ $1 == "--force" ]] && force=1
  _build_docker_args
  _build_image_docker "molecule/default/Dockerfile" "$DOCKER_IMAGE_MOLECULE" "$build_args" "" $force
}

# Installation de l'environnement ansible
function build_env() {
  # Initialisation poetry
  _init_poetry
  # Variables d'environnement
  _set_vars_env
#  # Registry Docker
  _install_docker_registry
#  # Construction des images Docker
  _build_docker_project "$1"
  _build_docker_molecule "$1"
}

# Execution d'une commande dans le container configuration
function run_env() {
  exec_command="/bin/bash"
  [[ -n "$1" ]] && ! [[ "$1" = "--force" ]] && exec_command=$*
  if [ "$(docker ps -a | grep -c $CONTAINER_NAME)" -gt 0 ]; then
    docker exec -it $CONTAINER_NAME bash
  else
    command="docker run --rm -it --name $CONTAINER_NAME --hostname $CONTAINER_NAME --network host --privileged \
      -v /var/run/docker.sock:/var/run/docker.sock:rw \
      -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
      -v ${PWD}:/app/demo-molecule \
      -w=/app/demo-molecule"
    [[ -f .proxy ]] && command="$command --env-file .proxy"
    command="$command $DOCKER_IMAGE_PROJECT $exec_command"
    echo "$command" && eval "$command"
  fi
}

if build_env "$*"; then
  run_env "$*";
fi
