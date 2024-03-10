#!/usr/bin/env bash
# @name Run
# @brief **run.sh** is a useful toolbox for initializing a Docker environment with Ansible and Molecule.
# @description
#   This toolbox enables you to perform the following actions:
#
#       * Initializing a Docker environment with Ansible and Molecule
#       * Build the Docker images required for this project
#       * Analyzing the syntax of Ansible code
#       * Installing Ansible dependencies

CURRENT_PATH="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
DOC_PATH="$CURRENT_PATH/docs"
PROJECT_NAME="demo-molecule"
DOCKER_PROJECT_IMAGE="$PROJECT_NAME:1.0.0"
DOCKER_MOLECULE_CONFIGS=()
DOCKER_MOLECULE_CONFIGS+=("dockerfiles/rockylinux8/Dockerfile;molecule-rocky8.8:1.0.0")
DOCKER_MOLECULE_CONFIGS+=("dockerfiles/ubuntu22/Dockerfile;molecule-ubuntu22.04:1.0.0")

declare -A COLORS=(
    [RED]='\033[1;31m'
    [GREEN]='\033[1;32m'
    [YELLOW]='\033[1;33m'
    [BLUE]='\033[1;34m'
    [WHITE]='\033[1;37m'
    [NOCOLOR]='\033[1;0m'
)

function info() {
    echo -e "${COLORS[WHITE]}$*${COLORS[NOCOLOR]}"
}

function warning() {
    echo -e "${COLORS[YELLOW]}$*${COLORS[NOCOLOR]}"
}

function debug() {
    [[ $VERBOSE -gt 0 ]] && echo -e "${COLORS[BLUE]}$*${COLORS[NOCOLOR]}"
}

function die() {
    echo -e "${COLORS[RED]}$*${COLORS[NOCOLOR]}"
}

# @description Check if docker is installed.
# @noargs
# @exitcode 0 If docker is installed.
# @exitcode 1 If docker is not installed.
function check_env_docker() {
    ! [[ -x "$(command -v docker)" ]] && die "Please install docker" && return 1
    return 0
}

# @description Building an image of the local environment.
# @noargs
# @exitcode 0 If successful.
# @exitcode 1 If an error was detected when building the Docker image.
function docker_build_env() {
    if ! docker_build "Dockerfile" "$DOCKER_PROJECT_IMAGE" "runtime"; then
        return 1
    fi
    return 0
}

# @description Building Docker images.
# @noargs
# @exitcode 0 If successful.
# @exitcode 1 If an error was detected when building the Docker image.
function docker_build_images() {
    # Building images for Molecule
    debug "Building images for Molecule"
    for docker_config in "${DOCKER_MOLECULE_CONFIGS[@]}"; do
        IFS=";" read -ra conf <<< "$docker_config"
        docker_file="${conf[0]}"
        docker_tag="${conf[1]}"
        if ! docker_build "$docker_file" "$docker_tag"; then
            return 1
        fi
    done
    return 0
}

# @description Building a Docker image.
# @noargs
# @exitcode 0 If successful.
# @exitcode 1 If no Docker file passed as parameter.
# @exitcode 2 If no Docker tag passed as parameter.
# @exitcode 3 If an error was detected during image pulling.
# @exitcode 4 If unable to delete Docker image.
# @exitcode 5 If an error was detected when building the Docker image.
function docker_build() {
    local docker_file=$1 image_tag=$2 target=$3
    local cmd_docker="" docker_images=""
    [[ -z $docker_file ]] && warning "No Docker file passed as parameter" && return 1
    [[ -z $image_tag ]] && warning "No Docker tag passed as parameter" && return 2
    # Pull docker images located in the Dockerfile
    read -ra docker_images <<< "$(< "$docker_file" grep "^FROM"|awk '{print $2}')"
    for docker_image in "${docker_images[@]}"; do
        if ! docker image inspect "$docker_image" 1>/dev/null 2>&1; then
            info "Pull $docker_image"
            if ! docker pull "$docker_image"; then
                warning "Unable to pull docker image"
                return 3
            fi
        fi
    done
    # Updating the arguments of the docker build command
    cmd_docker="DOCKER_BUILDKIT=1 docker build --file $docker_file --tag $image_tag"
    cmd_docker+=" --build-arg USER_ID=\"$(id -u)\" \
        --build-arg USER_GID=\"$(id -g)\"  \
        --build-arg DOCKER_GID=\"$(grep ^docker /etc/group|cut -d: -f3)\" "
    # Add target if value exists
    [[ -n $target ]] && cmd_docker+=" --target=$target"
    # If the force option exists, delete the docker image and add the --no-cache option to the command
    if [[ "$FORCE" -gt 0 ]]; then
        image_id=$(docker images "$image_tag" --format "{{.ID}}")
        if [[ -n "$image_id" ]]; then
            info "Deleting $image_tag"
            if ! docker image rm -f "$image_tag" 1>/dev/null; then
                warning "Unable to delete $image_tag image"
                return 4
            fi
        fi
        cmd_docker+=" --no-cache ."
    else
        cmd_docker+=" ."
    fi
    # Build Docker image if it doesn't already exist
    image_id=$(docker images "$image_tag" --format "{{.ID}}")
    if [[ -z "$image_id" ]]; then
        info "Building $image_tag"
        debug "$cmd_docker"
        if [[ $VERBOSE -gt 0 ]]; then
            if ! eval "$cmd_docker"; then
                return 5
            fi
        else
            if ! eval "$cmd_docker" 2>/dev/null 1>/dev/null; then
                return 5
            fi
        fi
    fi
    return 0
}

# @description Executing a command in the Docker container
# @noargs
# @exitcode 0 If successful.
# @exitcode 1 If no commands to execute.
# @exitcode 2 If an error has been detected during execution of the command.
function execute_cmd() {
    local cmd_container=""
    local build_image_molecule=1
    if [[ ${#CMD_DOCKER[@]} -eq 0 ]]; then
        die "No commands to execute!" && return 1
    fi
    # Build the command to be executed in the Docker container
    for i in "${!CMD_DOCKER[@]}"; do
        [[ -z ${CMD_DOCKER[$i]} ]] && continue
        [[ $i -eq 0 ]] && cmd_container+="${CMD_DOCKER[$i]}" && continue
        cmd_container+=" ${CMD_DOCKER[$i]}"
    done
    # Run the command in the Docker container
    ! cmd_run && return 2
    return 0
}

# @description Execute a command.
# @noargs
# @exitcode 0 If successful.
# @exitcode 1 If no commands to execute.
# @exitcode 2 If an error was encountered when executing the command in the Docker container.
function cmd_run() {
    if [[ -z $cmd_container ]]; then
        die "No commands to execute!" && return 1
    fi
    # Execute the command if you are already in the Docker container
    if [[ $ENV = "docker" ]]; then
        debug "$cmd_container"
        eval "$cmd_container"
    # Run the command in the Docker container
    else
        ! docker_run && return 2
    fi
    return 0
}

# @description Execute a command in the docker container.
# @noargs
# @exitcode 0 If successful.
# @exitcode 1 If PROJECT_NAME variable does not exist.
# @exitcode 2 If the docker environment is not installed.
# @exitcode 3 If an error was detected when building the Docker image of local environment.
# @exitcode 4 If an error was detected when building the Docker image of Molecule.
# @exitcode 5 If an error is encountered when executing the command directly in the Docker container.
# @exitcode 6 If an error is encountered when executing the command in the Docker container.
function docker_run() {
    # Check global variables
    if [[ -z $PROJECT_NAME ]]; then
        die "PROJECT_NAME variable does not exist!" && return 1
    fi
    local cmd_docker=""
    local container="$PROJECT_NAME" workdir="/app/$PROJECT_NAME"
    # Check if docker is installed
    ! check_env_docker && return 2
    # Building an image of the local environment
    ! docker_build_env && return 3
    # Building Docker images for Molecule if necessary
    if [[ ${build_image_molecule:-0} -gt 0 ]]; then
        ! docker_build_images && return 4
    fi
    # If the container name already exists, run the command directly
    if docker ps|grep "$container" 1>/dev/null; then
        debug "$cmd_container"
        if ! docker exec -it "$container" "$cmd_container"; then
            warning "Error executing command in Docker container"
            return 5
        fi
        return 0
    fi
    ! [[ -d "$(pwd)/.cache" ]] && mkdir "$(pwd)/.cache"
    # Building the Docker command to run
    cmd_docker="docker run --rm -it --name $container --privileged --network host \
        -v /var/run/docker.sock:/var/run/docker.sock:rw \
        -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
        -e ENV=docker \
        -w=$workdir \
        -v $(pwd)/ansible.cfg:$workdir/ansible.cfg \
        -v $(pwd)/.ansible-lint:$workdir/.ansible-lint \
        -v $(pwd)/.cache:$workdir/.cache \
        -v $(pwd)/run.sh:$workdir/run.sh \
        -v $(pwd)/requirements.yml:$workdir/requirements.yml \
        -v $(pwd)/inventories:$workdir/inventories \
        -v $(pwd)/collections:$workdir/collections \
        -v $(pwd)/roles:$workdir/roles \
        -v $(pwd)/roles.internal:$workdir/roles.internal \
        -v $(pwd)/molecule:$workdir/molecule \
        -v $(pwd)/docs:$workdir/docs \
        $DOCKER_PROJECT_IMAGE $cmd_container"
    # Display and execute command
    debug "$cmd_docker"
    if ! eval "$cmd_docker"; then
        return 6
    fi
    return 0
}

# @description Analysis of Ansible code syntax.
# @noargs
# @exitcode 0 If successful.
# @exitcode 0 If an error is encountered when analyzing Ansible code.
function lint_ansible() {
    # Build the lint command
    local cmd_container="ansible-lint"
    ! cmd_run && return 1
    return 0
}

# @description Installing Ansible dependencies.
# @noargs
# @exitcode 0 If successful.
# @exitcode 1 If an error is encountered when installing roles.
# @exitcode 2 If an error is encountered when installing collections.
function galaxy_install() {
    info "Installing Ansible dependencies"
    local cmd_container=""
    cmd_container="ansible-galaxy install -r requirements.yml"
    ! cmd_run && return 1
    cmd_container="ansible-galaxy collection install -r requirements.yml"
    ! cmd_run && return 2
    return 0
}

# @description Generate bash API documentation in Markdown format.
# @noargs
# @exitcode 0 If successful.
# @exitcode 1 If gawk is not installed.
function generate_doc() {
    # Checking prerequisites
    if ! command -v gawk &> /dev/null; then
        warning "Please install gawk to generate documentation"
        return 1
    fi
    # Generating the bash API documentation
    info "Generating API documentation"
    debug "Generating run.sh API documentation"
    ./bin/shdoc < "$CURRENT_PATH/run.sh" > "$DOC_PATH/run.md"
    return 0
}

# @description Execute tasks based on script parameters or user actions.
# @noargs
# @exitcode 0 If successful.
# @exitcode 1 If an error has been encountered displaying help.
# @exitcode 2 If an error was encountered while analyzing the code.
# @exitcode 3 If an error is encountered when installing roles and collections.
# @exitcode 4 If an error was encountered in generating the documentation.
# @exitcode 5 If an error is encountered when executing command in the Docker container.
function execute_tasks() {
    # Display help
    if [[ $HELP -gt 0 ]]; then
        ! display_help && return 1
        return 0
    fi
    # Linting code
    if [[ $LINTER -gt 0 ]]; then
        ! lint_ansible && return 2
    fi
    # Installing Ansible dependencies
    if [[ $INSTALL -gt 0 ]]; then
        ! galaxy_install && return 3
    fi
    # Generate the bash API documentation
    if [[ $DOC -gt 0 ]]; then
        ! generate_doc && return 4
    fi
    # Executing a command in the Docker container
    if [[ ${#CMD_DOCKER[@]} -gt 0 ]]; then
      ! execute_cmd && return 5
    fi
    return 0
}

# @description Display help.
# @noargs
# @exitcode 0 If successful.
function display_help() {
    local output=""
    output="
${COLORS[YELLOW]}Usage${COLORS[WHITE]} $(basename "$0") [OPTIONS] [COMMAND]\n
${COLORS[YELLOW]}Options:${COLORS[NOCOLOR]}
  ${COLORS[GREEN]}-h, --help${COLORS[WHITE]}                           Display help
  ${COLORS[GREEN]}-l, --lint${COLORS[WHITE]}                           Analyzing the syntax of Ansible code
  ${COLORS[GREEN]}-i, --install${COLORS[WHITE]}                        Installing Ansible dependencies
  ${COLORS[GREEN]}-f, --force${COLORS[WHITE]}                          Remove Docker image before build
  ${COLORS[GREEN]}-v, --verbose${COLORS[WHITE]}                        Make the command more talkative
${COLORS[YELLOW]}\nExamples:${COLORS[NOCOLOR]}
  ${COLORS[GREEN]}./$(basename -- "$0") molecule create${COLORS[WHITE]}             Use the provisioner to start the instances.
  ${COLORS[GREEN]}./$(basename -- "$0") molecule converge${COLORS[WHITE]}           Use the provisioner to configure instances.
  ${COLORS[GREEN]}./$(basename -- "$0") molecule verify${COLORS[WHITE]}             Run automated tests against instances.
  ${COLORS[GREEN]}./$(basename -- "$0") molecule test${COLORS[WHITE]}               Run a full test sequence.
  ${COLORS[GREEN]}./$(basename -- "$0") molecule login -h demo_01${COLORS[WHITE]}   Log in to demo_01 instance.
  ${COLORS[GREEN]}./$(basename -- "$0") molecule destroy${COLORS[WHITE]}            Use the provisioner to destroy the instances.
  ${COLORS[GREEN]}./$(basename -- "$0") --lint${COLORS[WHITE]}                      Launch Ansible code analysis
  ${COLORS[GREEN]}./$(basename -- "$0") --install${COLORS[WHITE]}                   Installing Ansible roles and collections.
  ${COLORS[GREEN]}./$(basename -- "$0") -v -l -i molecule create ${COLORS[WHITE]}   Analysis of code, installing dependencies and start the instances.
    "
    echo -e "$output\n"|sed '1d; $d'
    return 0
}

# @description Check options passed as script parameters.
# @noargs
# @exitcode 0 If successful.
function check_opts() {
    read -ra opts <<< "$@"
    local skip_check_opts=0;
    for opt in "${opts[@]}"; do
        if [[ $skip_check_opts -eq 0 ]]; then
            case "$opt" in
                -h|--help) HELP=1 ;;
                -l|--linter) LINTER=1 ;;
                -i|--install) INSTALL=1 ;;
                -d|--doc) DOC=1 ;;
                -f|--force) FORCE=1 ;;
                -v|--verbose) VERBOSE=1 ;;
                *) CMD_DOCKER+=("$opt") && skip_check_opts=1 ;;
            esac
        else
            CMD_DOCKER+=("$opt")
        fi
    done
    # Run bash by default if no options are passed to the script
    if [[ $((HELP+LINTER+INSTALL+DOC+${#CMD_DOCKER[@]})) -eq 0 ]]; then
        CMD_DOCKER=("/bin/bash")
    fi
    return 0
}

# @description Main function.
# @noargs
# @exitcode 0 If successful.
# @exitcode 1 If the options check failed.
# @exitcode 2 If task execution failed.
function main() {
    # Global variables
    local CMD_DOCKER=() HELP=0 LINTER=0 INSTALL=0 DOC=0 FORCE=0 VERBOSE=0
    # Check options
    ! check_opts "$@" && return 1
    ! execute_tasks && return 2
    return 0
}

main "$@"
