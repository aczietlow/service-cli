#!/bin/bash

# This script is running as root by default.
# Switching to the docker user can be done via "gosu docker <command>".

HOME_DIR='/home/docker'

DEBUG=${DEBUG:-0}
# Turn debugging ON when cli is started in the service mode
[[ "$1" == "supervisord" ]] && DEBUG=1
echo-debug ()
{
	[[ "$DEBUG" != 0 ]] && echo "$@"
}

uid_gid_reset()
{
	if [[ "$HOST_UID" != "$(id -u docker)" ]] || [[ "$HOST_GID" != "$(id -g docker)" ]]; then
		echo-debug "Updating docker user uid/gid to $HOST_UID/$HOST_GID to match the host user uid/gid..."
		usermod -u "$HOST_UID" -o docker >/dev/null 2>&1
		groupmod -g "$HOST_GID" -o users >/dev/null 2>&1
		# Make sure permissions are correct after the uid/gid change
		chown "$HOST_UID:$HOST_GID" -R ${HOME_DIR}
		chown "$HOST_UID:$HOST_GID" -R /var/www
	fi
}

xdebug_enable()
{
	echo-debug "Enabling xdebug..."
	php5enmod xdebug
}

codebase_init()
{
	echo-debug "Initializing codebase..."
	cd /var/www

	# Cleanup everything in the directory, including hidden files
	shopt -s dotglob
	rm -rf *

	# Clone the codebase as the docker user
	set -x
	gosu docker git clone --branch="$GIT_BRANCH" --depth 50 "$GIT_URL" .
	# Reset to a specific commit if passed
	( [[ "$GIT_COMMIT" != '' ]] || [[ "$GIT_COMMIT" != '""' ]] ) &&
		gosu docker git reset --hard "$GIT_COMMIT"
	set +x

	ls -la
}

# Docker user uid/gid mapping to the host user uid/gid
# '""' is used as an empty variable designation in yml files (can't used empty vars without warnings from compose)
# TODO: figure out a better way of checking for empty variables
( [[ "$HOST_UID" != '' ]] || [[ "$HOST_UID" != '""' ]] ) &&
	( [[ "$HOST_GID" != '' ]] || [[ "$HOST_GID" != '""' ]] ) &&
	uid_gid_reset

# Enable xdebug
[[ "$XDEBUG_ENABLED" != "0" ]] && xdebug_enable

# Codebase initialization
# '""' is used as an empty variable designation in yml files (can't used empty vars without warnings from compose)
# TODO: figure out a better way of checking for empty variables
( [[ "$GIT_URL" != '' ]] || [[ "$GIT_URL" != '""' ]] ) &&
	( [[ "$GIT_BRANCH" != '' ]] || [[ "$GIT_BRANCH" != '""' ]] ) &&
	codebase_init

# Initialization steps completed. Create a pid file to mark the container is healthy
echo-debug "Preliminary initialization completed"
touch /var/run/cli

# Execute passed CMD arguments
echo-debug "Executing the requested command..."
# Service mode (run as root)
if [[ "$1" == "supervisord" ]]; then
	gosu root supervisord -c /etc/supervisor/conf.d/supervisord.conf
# Command mode (run as docker user)
else
	gosu docker "$@"
fi
