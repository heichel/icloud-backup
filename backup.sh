#!/bin/sh

. "$(dirname "$0")/config.sh"

set -eu

download_command_bin="${DOWNLOAD_COMMAND%% *}"
evict_command_bin="${EVICT_COMMAND%% *}"

require_command op
require_command borg
require_command find
require_command "$download_command_bin"
require_command "$evict_command_bin"

printInfo "Starting iCloud Drive Backup"

# For each of the important directories in iCloud Drive, we back them up as follows:
#   1.  Force iCloud to download them using the `brctl` utility (this would happen
#       implicitly when runing Borg, but then Borg detects them as 'changed during
#       backup' and incremental backups won't work properly).
#   2.  Run Borg to back up that directory.
#   3.  Delete the download using the `brctl` utility to free up local disk space
#       and avoid the whole iCloud Drive being cached locally during the backup
#       process.
archive_name=$(date '+%Y-%m-%dT%H-%M-%S')

download_target() {
	target_path="$1"
	printInfo "Downloading $target_path"
	find "$target_path" -type f -exec sh -c '
		command_template="$1"
		file_path="$2"
		eval "$command_template \"\$file_path\""
	' sh "$DOWNLOAD_COMMAND" '{}' ';'
}

backup_target() {
	target_name="$1"
	target_path="$2"

	printInfo "Backing up '$target_name' to archive '$archive_name'"
	borg create --stats --show-rc "$BORG_REPO::$archive_name" "$target_path"
}

evict_target() {
	target_path="$1"
	printInfo "Evicting local downloads for $target_path"
	find "$target_path" -type f -exec sh -c '
		command_template="$1"
		file_path="$2"
		eval "$command_template \"\$file_path\""
	' sh "$EVICT_COMMAND" '{}' ';'
}

printf '%s\n' "$ICLOUD_BACKUP_DIRS" | while IFS= read -r folder_name || [ -n "$folder_name" ]; do
	if [ -z "$folder_name" ]; then
		continue
	fi

	target_path="$ICLOUD_DRIVE_ROOT/$folder_name"

	if [ ! -e "$target_path" ]; then
		printError "Skipping missing iCloud folder: $target_path"
		continue
	fi

	download_target "$target_path"
	backup_target "$folder_name" "$target_path"
	evict_target "$target_path"
done

printInfo "iCloud Drive Backup Complete"
