#!/bin/bash
#
# Backup personal data from trakt.tv service.
#
# This script authenticates with the trakt.tv API so that subsequent
# requests for personal data can succeed. Authentication information is
# stored in a separate file for each account. The script can be used as
# a cronjob for regular re-authentication.
#
# (c) Copyright 2015 Michael Starzinger. All Rights Reserved.
# Use of this work is governed by a license found in the LICENSE file.
#

BASE="$(cd "$(dirname "$0")" && pwd)"
CLIENT_FILE="$BASE/api-client"

# Parse all command line options.
while [[ $# > 1 ]]; do
  case "$1" in
    -c|--code)
      AUTH_CODE="$2"
      shift
      ;;
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

# The API client secret we are using to authenticate.
CLIENT_SEC=$(grep "CLIENT_SECRET" "$CLIENT_FILE" | awk -F '=' '{ print $2 }')
if [ -z "$CLIENT_SEC" ]; then
  echo "No CLIENT_SECRET has been specified."
  exit 1
fi

# Check that the 'auth' file exists.
AUTH_FILE="$BASE/auth-$USERNAME"
if [ ! -f "$AUTH_FILE" ]; then
  echo "Creating a brand new 'auth-$USERNAME' file ..."
  cat <<EOF > "$AUTH_FILE"
# This file has been automatically generated.
# Do not edit, run trakt-auth.sh script instead!
EOF
fi

# Check that permissions of 'auth' are good.
if [ "$(stat -c "%a" "$AUTH_FILE")" != "600" ]; then
  echo "Fixing permission of 'auth-$USERNAME' file ..."
  chmod 600 "$AUTH_FILE"
fi

# The authentication refresh token to be used.
AUTH_REFRESH=$(grep -e '^[^#]' "$AUTH_FILE" | tail -n 1 | awk -F ' ' '{ print $3 }')
if [ -z "$AUTH_REFRESH" ] && [ -z "$AUTH_CODE" ]; then
  echo "No authentication code or refresh token provided."
  exit 1
fi
if [ -n "$AUTH_CODE" ]; then
  GRANT_TYPE="authorization_code"
  GRANT_FIELD="code"
  GRANT_DATA="$AUTH_CODE"
else
  GRANT_TYPE="refresh_token"
  GRANT_FIELD="refresh_token"
  GRANT_DATA="$AUTH_REFRESH"
fi

# Request headers to be sent along.
CONTENT_TYPE="Content-Type: application/json"

# Post the authentication request.
URL="https://api-v2launch.trakt.tv/oauth/token"
RESPONSE=$(curl --silent --header "$CONTENT_TYPE" --data @- "$URL" <<EOF
{
  "$GRANT_FIELD": "$GRANT_DATA",
  "client_id": "$CLIENT_ID",
  "client_secret": "$CLIENT_SEC",
  "redirect_uri": "urn:ietf:wg:oauth:2.0:oob",
  "grant_type": "$GRANT_TYPE"
}
EOF
)

# Extract the new authentication access and refresh token.
NEW_ACCESS=$(echo "$RESPONSE" | sed -n 's/.*"access_token":"\([^"]*\)".*$/\1/p')
NEW_REFRESH=$(echo "$RESPONSE" | sed -n 's/.*"refresh_token":"\([^"]*\)".*$/\1/p')
if [ -z "$NEW_ACCESS" ] || [ -z "$NEW_REFRESH" ]; then
	echo "Authentication seems to have failed."
	echo "$RESPONSE"
	exit 1
fi

# Record new authentication information 'auth' file.
TIMESTAMP=$(date -u +%Y-%m-%d@%H:%M:%S)
echo "$TIMESTAMP $NEW_ACCESS $NEW_REFRESH $GRANT_TYPE" >> "$AUTH_FILE"
