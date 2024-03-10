# demo-molecule

<p align="left">
    <a href="https://github.com/christopherlouet/demo-molecule/actions?query=workflow%3Aansible-lint">
        <img src="https://github.com/christopherlouet/demo-molecule/workflows/ansible-lint/badge.svg" alt="Build Status">
    </a>
    <img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="license">
</p>

### 💡 About

A demo project to initialize a Docker environment with **Ansible Molecule**.
The project is configured to use Docker as the driver for instance creation.

We deploy the components in Docker containers, demo_01 and demo_02:

* **demo_01**: container created from a Rocky Linux Docker image
* **demo_02**: container created from a Ubuntu Docker image

Images in the **dockerfiles** folder are configured to use **systemd** in Docker containers, 
so that services can be **restarted**.

### 🚧 Requirements

* A Linux distribution
* Docker

### 🔍 Usage

```bash
Usage run.sh [OPTIONS] [COMMAND]

Options:
  -h, --help                           Display help
  -l, --lint                           Analyzing the syntax of Ansible code
  -i, --install                        Installing Ansible dependencies
  -f, --force                          Remove Docker image before build
  -v, --verbose                        Make the command more talkative
```

#### 💻 Examples of Ansible molecule commands

Use the provisioner to **start** the instances:

```bash
./run.sh molecule create
```

Use the provisioner to **configure** instances and deploy components:

```bash
./run.sh molecule converge
```

In a browser, you can check that the components are properly deployed:

* http://localhost:8080
* http://localhost:8090

Run **automated tests** against instances:

```bash
./run.sh molecule verify
```

Run a **full test** sequence:

```bash
./run.sh molecule test
```

Use the provisioner to **destroy** the instances:

```bash
./run.sh molecule destroy
```

Analysis of code, installing dependencies and start the instances:

```bash
./run.sh -v -l -i molecule create
```

#### 👽 Miscellaneous

Launch Ansible **code analysis**:

```bash
./run.sh --lint
```

Installing Ansible **roles** and **collections**:

```bash
./run.sh --install
```

### 📜  License

Distributed under the MIT License.
