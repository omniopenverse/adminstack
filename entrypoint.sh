#!/bin/bash
set -e  # Exit on error

# Check if /var/run/docker.sock exists, create a group with its GID, 
# and add adminstack user to that group
ensureDockerSockGroup() {
	local sock_file="/var/run/docker.sock"
	if [ -e "$sock_file" ]; then
		local gid=$(stat -c '%g' "$sock_file")
		local group_name="docker_sock_${gid}"
		if ! getent group "$group_name" > /dev/null; then
			sudo groupadd -g "$gid" "$group_name"
		fi
		sudo usermod -aG "$group_name" adminstack
	fi
}

# Function to set default boolean values for environment variables
# If the variable is set to "true" or "false", it will be exported as such.
# If the variable is not set, it will be assigned a default value.
setDefaultBooleanValue() {
	local var="${!1:-}"
	local var_name="$1"
	local default_value="$2"

	if [[ "$var" == "true" ]]; then
		export "$var_name"="true"
	elif [[ "$var" == "false" ]]; then
		export "$var_name"="false"
	else
		export "$var_name"="$default_value"
	fi
}

# Set default values for environment variables if they are not set
setDefaultsValue() {
	local var_name="$1"
	local default_value="$2"

	if [ -z "${!var_name}" ]; then
		export "$var_name"="$default_value"
	fi
}

# Function to set Git global configuration
# It sets the Git configuration if variables are provided.
setGitGlobalConfig() {
	local user_name="${GIT_USER_NAME:-}"
	local user_email="${GIT_USER_EMAIL:-}"

	if [ -n "$user_name" ]; then
		git config --global user.name "$user_name"
	fi
	if [ -n "$user_email" ]; then
		git config --global user.email "$user_email"
	fi
}

prepareServerForSsh() {
	local START_SSH_SERVER=$1

	# Check if the SSH server should be started
	if [ "$START_SSH_SERVER" != "true" ]; then
		echo "SSH server is not set to start. Skipping SSH setup."
		return
	fi
	# Ensure the .ssh directory exists
	if [ ! -d ~/.ssh ]; then
		echo "Creating .ssh directory..."
		mkdir --parent --mode 700 ~/.ssh
	fi
	# Generate SSH keys if they do not exist
	if [ ! -f ~/.ssh/id_rsa ]; then
		echo "Generating SSH keys..."
		ssh-keygen -t rsa -f ~/.ssh/id_rsa -N ""
	else
		echo "SSH keys already exist."
	fi
}

# Set default values for environment variables
setDefaultsValue 		VSCODE_SERVER_PASSWORD 	"password"
setDefaultBooleanValue 	START_SSH_SERVER 		"false"
setDefaultBooleanValue 	START_VSCODE_SERVER 	"false"
setDefaultBooleanValue 	START_JUPYTER_SERVER 	"false"

# Prepare the server for SSH if the environment variable is set
prepareServerForSsh "$START_SSH_SERVER"

# Generate the supervisor configuration file with environment variables
PASSWORD="${VSCODE_SERVER_PASSWORD:-password}" \
envsubst < /etc/supervisor/conf.d/supervisord.conf > /home/adminstack/.config/supervisor/supervisord.conf

# Ensure the docker socket group exists and add the adminstack user to it
ensureDockerSockGroup

# Set Git global configuration if user name and email are provided
setGitGlobalConfig

# Start the supervisor application
/usr/bin/supervisord -c /home/adminstack/.config/supervisor/supervisord.conf
