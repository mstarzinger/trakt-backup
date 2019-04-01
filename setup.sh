#!/bin/bash
#
# Backup personal data from trakt.tv service.
#
# This script initializes local data so that the trakt.tv API can be
# accessed and other scripts work property. Usually this only has to be
# executed once to get everything going.
#
# (c) Copyright 2015 Michael Starzinger. All Rights Reserved.
# Use of this work is governed by a license found in the LICENSE file.
#

BASE="$(cd "$(dirname "$0")" && pwd)"

# Check that the 'api-client' file exits.
CLIENT_FILE="$BASE/api-client"
if [ ! -f "$CLIENT_FILE" ]; then
  echo "Creating a brand new 'api-client' file ..."
  cat <<EOF > "$CLIENT_FILE"
# This file has been automatically generated.
# Do not edit, run the setup.sh script instead!
CLIENT_ID=
CLIENT_SECRET=
EOF
fi

# Check that permissions of 'api-client' are good.
if [ "$(stat -c "%a" "$CLIENT_FILE")" != "600" ]; then
  echo "Fixing permission of 'api-client' file ..."
  chmod 600 "$CLIENT_FILE"
fi

# Ask for CLIENT_ID in 'api-client' file.
CLIENT_ID=$(grep "CLIENT_ID" "$CLIENT_FILE" | awk -F '=' '{ print $2 }')
echo "Setting CLIENT_ID in the 'api-client' file ..."
echo "  Hit [ENTER] to leave it unchanged."
echo "  Old CLIENT_ID: $CLIENT_ID"
read -p "  New CLIENT_ID: " CLIENT_ID_NEW
if [ -n "$CLIENT_ID_NEW" ]; then
  echo "Updating CLIENT_ID field ..."
  sed -i -e "s/^CLIENT_ID=.*$/CLIENT_ID=$CLIENT_ID_NEW/" "$CLIENT_FILE"
fi

# Ask for CLIENT_SECRET in 'api-client' file.
CLIENT_SEC=$(grep "CLIENT_SECRET" "$CLIENT_FILE" | awk -F '=' '{ print $2 }')
echo "Setting CLIENT_SECRET in the 'api-client' file ..."
echo "  Hit [ENTER] to leave it unchanged."
echo "  Old CLIENT_SECRET: $CLIENT_SEC"
read -p "  New CLIENT_SECRET: " CLIENT_SEC_NEW
if [ -n "$CLIENT_SEC_NEW" ]; then
  echo "Updating CLIENT_SECRET field ..."
  sed -i -e "s/^CLIENT_SECRET=.*$/CLIENT_SECRET=$CLIENT_SEC_NEW/" "$CLIENT_FILE"
fi
