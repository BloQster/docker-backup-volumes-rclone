#!/bin/bash
set -e

if [ -z "$BACKUP_TARGET" ]; then
  echo "BACKUP_TARGET not set."
  exit 1
fi

export RCLONE_CONFIG_FILE=$(echo ~)/.rclone.conf

if [ ! -f "$RCLONE_CONFIG_FILE" ]; then
  if [ -n "$RCLONE_CONFIG" ]; then
    echo "$RCLONE_CONFIG" > "$RCLONE_CONFIG_FILE"
  else
    echo "rclone config file does not exist and is not present in the environment variables."
    exit 2
  fi
fi

: ${BACKUP_SOURCEDIR=/docker-volumes}
: ${NUM_TRANSFERS=10}
: ${NUM_CHECKERS=15}
: ${STATS_FREQUENCY=30s}

# For each directory in the volume folder do:
for directory_name in $(find $BACKUP_SOURCEDIR/* -maxdepth 0 -type d -printf "%f\n"); do
	# If the directory is a named volume, i.e. no hexadecimal, 64 characters long folder name
	if [ -z $(echo $directory_name | grep -E '[0-9a-f]{64}') ]; then
		echo "Syncing docker volume $directory_name"
		# rclone sync it to the target directory and save permissions to a file next to it
		rclone mkdir $BACKUP_TARGET/$directory_name
		rclone sync $BACKUP_SOURCEDIR/$directory_name $BACKUP_TARGET/$directory_name/ --delete-after --transfers "$NUM_TRANSFERS" --checkers "$NUM_CHECKERS" --retries 10 --stats "$STATS_FREQUENCY" --ask-password=false --log-file "/tmp/$directory_name.log" $ADDITIONAL_RCLONE_PARAMS
		getfacl -RPpn $BACKUP_SOURCEDIR/$directory_name > /tmp/$directory_name.meta
		rclone move /tmp/$directory_name.meta $BACKUP_TARGET/$directory_name/ --retries 10 --stats "$STATS_FREQUENCY" --ask-password=false --log-file "/tmp/$directory_name.acl.log"
	fi
done
