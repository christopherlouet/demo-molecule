# Run

**run.sh** is a useful toolbox for initializing a Docker environment with Ansible and Molecule.

## Overview

This toolbox enables you to perform the following actions:

* Initializing a Docker environment with Ansible and Molecule
* Build the Docker images required for this project
* Analyzing the syntax of Ansible code
* Installing Ansible dependencies

## Index

* [check_env_docker](#checkenvdocker)
* [docker_build_env](#dockerbuildenv)
* [docker_build_images](#dockerbuildimages)
* [docker_build](#dockerbuild)
* [execute_cmd](#executecmd)
* [cmd_run](#cmdrun)
* [docker_run](#dockerrun)
* [lint_ansible](#lintansible)
* [galaxy_install](#galaxyinstall)
* [generate_doc](#generatedoc)
* [execute_tasks](#executetasks)
* [display_help](#displayhelp)
* [check_opts](#checkopts)
* [main](#main)

### check_env_docker

Check if docker is installed.

_Function has no arguments._

#### Exit codes

* **0**: If docker is installed.
* **1**: If docker is not installed.

### docker_build_env

Building an image of the local environment.

_Function has no arguments._

#### Exit codes

* **0**: If successful.
* **1**: If an error was detected when building the Docker image.

### docker_build_images

Building Docker images.

_Function has no arguments._

#### Exit codes

* **0**: If successful.
* **1**: If an error was detected when building the Docker image.

### docker_build

Building a Docker image.

_Function has no arguments._

#### Exit codes

* **0**: If successful.
* **1**: If no Docker file passed as parameter.
* **2**: If no Docker tag passed as parameter.
* **3**: If an error was detected during image pulling.
* **4**: If unable to delete Docker image.
* **5**: If an error was detected when building the Docker image.

### execute_cmd

Executing a command in the Docker container

_Function has no arguments._

#### Exit codes

* **0**: If successful.
* **1**: If no commands to execute.
* **2**: If an error has been detected during execution of the command.

### cmd_run

Execute a command.

_Function has no arguments._

#### Exit codes

* **0**: If successful.
* **1**: If no commands to execute.
* **2**: If an error was encountered when executing the command in the Docker container.

### docker_run

Execute a command in the docker container.

_Function has no arguments._

#### Exit codes

* **0**: If successful.
* **1**: If PROJECT_NAME variable does not exist.
* **2**: If the docker environment is not installed.
* **3**: If an error was detected when building the Docker image of local environment.
* **4**: If an error was detected when building the Docker image of Molecule.
* **5**: If an error is encountered when executing the command directly in the Docker container.
* **6**: If an error is encountered when executing the command in the Docker container.

### lint_ansible

Analysis of Ansible code syntax.

_Function has no arguments._

#### Exit codes

* **0**: If successful.
* **0**: If an error is encountered when analyzing Ansible code.

### galaxy_install

Installing Ansible dependencies.

_Function has no arguments._

#### Exit codes

* **0**: If successful.
* **1**: If an error is encountered when installing roles.
* **2**: If an error is encountered when installing collections.

### generate_doc

Generate bash API documentation in Markdown format.

_Function has no arguments._

#### Exit codes

* **0**: If successful.
* **1**: If gawk is not installed.

### execute_tasks

Execute tasks based on script parameters or user actions.

_Function has no arguments._

#### Exit codes

* **0**: If successful.
* **1**: If an error has been encountered displaying help.
* **2**: If an error was encountered while analyzing the code.
* **3**: If an error is encountered when installing roles and collections.
* **4**: If an error was encountered in generating the documentation.
* **5**: If an error is encountered when executing command in the Docker container.

### display_help

Display help.

_Function has no arguments._

#### Exit codes

* **0**: If successful.

### check_opts

Check options passed as script parameters.

_Function has no arguments._

#### Exit codes

* **0**: If successful.

### main

Main function.

_Function has no arguments._

#### Exit codes

* **0**: If successful.
* **1**: If the options check failed.
* **2**: If task execution failed.

