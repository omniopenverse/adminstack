#!/bin/bash
set -e  # Exit on error

# Check if the environment variables are set to true
# and return "true" or "false" accordingly
# Usage: check VARIABLE_NAME
# Example: check START_SSH_SERVER
# Returns "true" if the variable is set to "true", otherwise returns "false"
check() {
	local var="${!1:-}"
	if [[ "$var" == "true" ]]; then
		echo "true"
	else
		echo "false"
	fi
}

# Ensure the necessary environment variables are set
# If not set, default them to "false"
# This allows the supervisor configuration to be generated correctly
# and prevents errors during startup
if [[ -n "$VSCODE_SERVER_PASSWORD" ]]; then
	export PASSWORD="$VSCODE_SERVER_PASSWORD"
else
	export PASSWORD="password"  # Default password for code-server
fi
START_SSH_SERVER="$(check START_SSH_SERVER)" \
START_VSCODE_SERVER="$(check START_VSCODE_SERVER)" \
START_JUPYTER_SERVER="$(check START_JUPYTER_SERVER)" \
envsubst < /etc/supervisor/conf.d/supervisord.conf > /home/adminstack/.config/supervisor/supervisord.conf

# Start the supervisor application
/usr/bin/supervisord -c /home/adminstack/.config/supervisor/supervisord.conf
