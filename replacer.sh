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
OLD_DB="$OLD_CONFIG/app.db"
DB="/root/.calibre-web/app.db"
OLD_META_TEMP="$OLD_BASE/metadata_temp"
META_TEMP="$CONFIG/metadata_temp"
OLD_META_LOGS="$OLD_BASE/metadata_change_logs"
META_LOGS="$CONFIG/metadata_change_logs"
INGEST="cwa-book-ingest"
CONVERSION=".cwa_conversion_tmp"

function replacer() {
    echo "Patching files..." && sleep 2
    cd $BASE
    sed -i "s|\"/calibre-library\"| \"/opt/calibre-web\"|" dirs.json ./scripts/auto_library.py
    sed -i -e "s|\"$OLD_CONFIG/$CONVERSION\"| \"$CONFIG/$CONVERSION\"|" \
        -e "s|\"/$INGEST\"| \"/opt/$INGEST\"|" dirs.json

    FILES=$(find ./scripts ./root/app/calibre-web/cps -type f -name "*.py")

    for file in $FILES; do
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

    # Deal with edge case(s)
    sed -i "s|\"/admin$CONFIG\"|\"/admin$OLD_CONFIG\"|" ./root/app/calibre-web/cps/admin.py
    sed -i "s|\"$CONFIG/post_request\"|\"$OLD_CONFIG/post_request\"|" ./root/app/calibre-web/cps/cwa_functions.py
    sed -i -e "/^# Define user/,/^os.chown/d" -e "/nbp.set_l\|self.set_l/d" -e "/def set_libr/,/^$/d" \
        ./scripts/convert_library.py ./scripts/kindle_epub_fixer.py ./scripts/ingest_processor.py
}

replacer && echo "Files patched" || echo "Oh fuck what just happened??"
