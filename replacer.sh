#! /usr/bin/env bash

# Going to try to use bash and sed to patch all the files we need to patch for CWA in LXC
# Author: vhsdream
# Year: 2025
# License: MIT

# Global vars
OLD_BASE="/app/calibre-web-automated"
BASE="/opt/cwa"
OLD_CONFIG="/config"
CONFIG="/var/lib/cwa"
OLD_SCRIPTS="$OLD_BASE/scripts"
SCRIPTS="$BASE/scripts"
OLD_APP="$OLD_BASE/root/app/calibre-web/cps"
APP="$BASE/root/app/calibre-web/cps"
OLD_DB="$OLD_CONFIG/app.db"
DB="/root/.calibre-web/app.db"
OLD_META_TEMP="$OLD_BASE/metadata_temp"
META_TEMP="$CONFIG/metadata_temp"
OLD_META_LOGS="$OLD_BASE/metadata_change_logs"
META_LOGS="$CONFIG/metadata_change_logs"

# /opt/cwa/dirs.json
OLD_INGEST="/cwa-book-ingest"
NEW_INGEST="/opt/cwa-book-ingest"
OLD_LIBRARY="/calibre-library"
NEW_LIBRARY="/opt/calibre-web"
OLD_CONVERSION_DIR="$OLD_CONFIG/.cwa_conversion_tmp"
NEW_CONVERSION_DIR="$CONFIG/.cwa_conversion_tmp"

# new scripts can be done by cat <<EOFing

# start with dirs.json as that is referenced a lot

# cd $BASE

sed -i -e "s|\"$OLD_INGEST\"| \"$NEW_INGEST\"|" \
    -e "s|\"$OLD_LIBRARY\"| \"$NEW_LIBRARY\"|" \
    -e "s|\"$OLD_CONVERSION_DIR\"| \"$NEW_CONVERSION_DIR\"|" dirs.json

# Then the scripts folder

# cd scripts
PYTHON_SCRIPTS=$(find ./scripts ./root/app/calibre-web/cps -type f -name "*.py")
# note: the python files in APP may need special treatment due to the metadata stuff being relocated (or do that first)

for file in $PYTHON_SCRIPTS; do
    if grep "$OLD_META_TEMP" "$file"; then
        sed -i "s|$OLD_META_TEMP|$META_TEMP|g" "$file"
    fi
    if grep "$OLD_META_LOGS" "$file"; then
        sed -i "s|$OLD_META_LOGS|$META_LOGS|g" "$file"
    fi
    if grep "$OLD_DB" "$file"; then
        sed -i "s|$OLD_DB|$DB|g" "$file"
    fi
    if grep "$OLD_BASE" "$file"; then
        sed -i "s|$OLD_BASE|$BASE|g" "$file"
    fi
    if grep "$OLD_CONFIG" "$file"; then
        sed -i "s|$OLD_CONFIG|"$CONFIG"|g" "$file"
    fi
done
