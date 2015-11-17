#!/bin/bash
#
# Backup personal data from trakt.tv service.
#
# This script downloads my personal cloud data from the aforementioned
# service and dumps it to the console in a machine readable format. It
# can be used as a cronjob to produce regular backups.
#
# (c) Copyright 2015 Michael Starzinger. All Rights Reserved.
#

BASE="$(cd "$(dirname "$0")" && pwd)"
CLIENT_FILE="$BASE/api-client"

# The list of data buckets to be downloaded.
read -d ' ' BACKUP_PATHS <<EOF
watchlist/movies
watchlist/shows
watchlist/seasons
watchlist/episodes
ratings/movies
ratings/shows
ratings/seasons
ratings/episodes
history/movies
history/shows
history/seasons
history/episodes
collection/movies
collection/shows
watched/movies
watched/shows
comments/all
followers
following
EOF

# Parse all command line options.
while [[ $# > 1 ]]; do
  case "$1" in
    -u|--username)
      USERNAME="$2"
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
  shift
done

# Check that a username has been provided.
if [ -z "$USERNAME" ]; then
  echo "No username has been provided."
  exit 1
fi

# The API client ID we are using to connect.
CLIENT_ID=$(grep "CLIENT_ID" "$CLIENT_FILE" | awk -F '=' '{ print $2 }')
if [ -z "$CLIENT_ID" ]; then
  echo "No CLIENT_ID has been specified."
  exit 1
fi

# Check that the 'auth' file exists.
AUTH_FILE="$BASE/auth-$USERNAME"
if [ ! -f "$AUTH_FILE" ]; then
  echo "No 'auth-$USERNAME' file present."
  exit 1
fi

# The authentication refresh token to be used.
AUTH_TOKEN=$(grep -e '^[^#]' "$AUTH_FILE" | tail -n 1 | awk -F ' ' '{ print $2 }')
if [ -z "$AUTH_TOKEN" ]; then
  echo "No authentication token provided."
  exit 1
fi

# Create temporary working directory.
TMP_DIR=$(mktemp -d)

# Output will be packed into archive.
TIMESTAMP=$(date -u +%Y%m%d)
OUT_FILE="$BASE/backup-$USERNAME-$TIMESTAMP.tar.gz"
OUT_DIR="$TMP_DIR/backup-$USERNAME-$TIMESTAMP"
mkdir "$OUT_DIR"

# Download all relevant data into files.
for BACKUP_PATH in $BACKUP_PATHS; do
  URL="https://api-v2launch.trakt.tv/users/$USERNAME/$BACKUP_PATH"
  FILE=$(echo $BACKUP_PATH | sed -e 's|/|_|g')
  curl --silent\
    --header "Authorization: Bearer $AUTH_TOKEN" \
    --header "Content-Type: application/json" \
    --header "trakt-api-version: 2" \
    --header "trakt-api-key: $CLIENT_ID" \
    --output "$OUT_DIR/$FILE.json" "$URL"
done

# Dump the result into a file.
tar -c -z -f "$OUT_FILE" -C "$TMP_DIR" "backup-$USERNAME-$TIMESTAMP"
if [ ! -f "$OUT_FILE" ]; then
  echo "No output file has been produced."
  exit 1
fi

# Cleanup after ourself.
rm -r "$TMP_DIR"
