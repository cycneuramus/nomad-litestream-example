#!/bin/sh

cfg=/local/litestream.yml

for db in "$@"; do
	db_path=/data/"$db"
	snapshots_full=$(litestream snapshots -config "$cfg" "$db_path")

	echo "snapshots for $db:"
	echo "$snapshots_full"

	snapshots=$(echo "$snapshots_full" | grep -vc "replica")

	if [ "$snapshots" -ge 1 ] && [ -f "$db_path" ]; then
		echo "snapshot and db at path found; backing up db at path before restore"
		mv "$db_path" "$db_path".bak
	elif [ "$snapshots" -ge 1 ] && [ ! -f "$db_path" ]; then
		echo "snapshot found and no db at path; restoring snapshot"
	elif [ "$snapshots" -eq 0 ] && [ -f "$db_path" ]; then
		echo "no snapshot found but db at path; treating db at path as authoritative"
		exit 0
	elif [ "$snapshots" -eq 0 ] && [ ! -f "$db_path" ]; then
		echo "no snapshot or db at path found; touching mock files"
		touch "$db_path" # for the benefit of docker bind mount
	fi

	litestream restore \
		-if-replica-exists \
		-if-db-not-exists \
		-config /local/litestream.yml \
		"$db_path"
done
