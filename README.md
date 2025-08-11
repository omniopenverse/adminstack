# omniopenverse/adminstack

Adminstack is a powerful, ready-to-use development environment for cloud-native, Kubernetes, and DevOps workflows. It is designed to be run as a Docker container, with support for VS Code remote development, SSH, Jupyter, and more.

## Features

- Pre-installed tools: Python, Docker CLI, Kubernetes (kubectl, kind, minikube), Ansible, GitHub CLI, code-server (VS Code in browser), Jupyter, and more
- Supervisor-based service management
- SSH server, Jupyter server, and VS Code server (code-server)
- User-friendly bash environment and VS Code settings
- Git global configuration via environment variables
- Ready for mounting host directories and Docker socket

## Quick Start

### 1. Build and Run with Docker Compose

Clone the repository and run:

```bash
docker-compose up --build
```

You can customize environment variables and volumes in `docker-compose.yml` and `example.docker-compose.override.yml`.

### 2. Environment Variables

Set these in your compose file or as Docker environment variables:

- `START_SSH_SERVER` (true/false): Start SSH server
- `START_VSCODE_SERVER` (true/false): Start VS Code server
- `START_JUPYTER_SERVER` (true/false): Start Jupyter server
- `VSCODE_SERVER_PASSWORD`: Password for code-server
- `GIT_USER_NAME`, `GIT_USER_EMAIL`: Set global git config

### 3. Volumes and Docker Socket

- Mount your code into `/home/adminstack/shared` for editing
- Mount `/var/run/docker.sock` for Docker CLI access inside the container

### 4. VS Code: Connect to Dev Container

You can use VS Code's "Remote - Containers" extension to connect directly to the running adminstack container:

#### Steps:
1. Install the following VS Code extensions:
   - Remote - Containers (`ms-vscode-remote.remote-containers`)
   - Jupyter (`ms-toolsai.jupyter`)
2. Start the container (see above)
3. In VS Code, open the Command Palette (`Ctrl+Shift+P`), select `Remote-Containers: Attach to Running Container...`, and choose `adminstack`
4. You can now use VS Code as if you were developing locally, with all tools pre-installed

### 5. DockerHub Usage

You can pull the image directly from DockerHub:

```bash
docker pull omniopenverse/adminstack:latest
```
Or use a specific version:
```bash
docker pull omniopenverse/adminstack:<version>
```

## Entrypoint and Service Management

The container uses `entrypoint.sh` to set up environment variables, user permissions, and start services via Supervisor. See the script for customization options.

## Example Compose Override

See `example.docker-compose.override.yml` for advanced configuration, including mounting SSH keys and host directories.

## License

MIT
