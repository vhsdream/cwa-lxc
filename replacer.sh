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
APP="$BASE/root/app/calibre-web/cps"

function replacer() {
    echo "Patching files..." && sleep 2
    cd $BASE
    sed -i "s|\"/calibre-library\"| \"/opt/calibre-web\"|" dirs.json ./scripts/auto_library.py
    sed -i -e "s|\"$OLD_CONFIG/$CONVERSION\"| \"$CONFIG/$CONVERSION\"|" \
        -e "s|\"/$INGEST\"| \"/opt/$INGEST\"|" dirs.json

    FILES=$(find ./scripts "$APP" -type f -name "*.py")
    OLD_PATHS=("$OLD_META_TEMP" "$OLD_META_LOGS" "$OLD_DB" "$OLD_BASE" "$OLD_CONFIG")
    NEW_PATHS=("$META_TEMP" "$META_LOGS" "$DB" "$BASE" "$CONFIG")

    for file in $FILES; do
        for ((path=0;path<${#OLD_PATHS[@]};path++))
        do
            if grep "${OLD_PATHS[path]}" "$file"; then
                sed -i "s|${OLD_PATHS[path]}|${NEW_PATHS[path]}|g" "$file"
            fi
        done
    done

    # Deal with edge case(s)
    sed -i -e "s|\"/admin$CONFIG\"|\"/admin$OLD_CONFIG\"|" \
        -e "s|app/LSCW_RELEASE|opt/calibre-web/calibreweb_version.txt|g" \
        -e "s|app/CWA_RELEASE|opt/Calibre-Web-Automated_version.txt|g" \
        -e "s|app/KEPUBIFY_RELEASE|opt/kepubify/version.txt|g" \
        -e "s/lscw_version/calibreweb_version/g" \
        -e "s|app/cwa_update_notice|opt/.cwa_update_notice|g" \
        $APP/admin.py $APP/render_template.py
    sed -i "s|\"$CONFIG/post_request\"|\"$OLD_CONFIG/post_request\"|" $APP/cwa_functions.py
    sed -i -e "/^# Define user/,/^os.chown/d" -e "/nbp.set_l\|self.set_l/d" -e "/def set_libr/,/^$/d" \
        ./scripts/convert_library.py ./scripts/kindle_epub_fixer.py ./scripts/ingest_processor.py
    sed -i -n '/Linuxserver.io/{x;d;};1h;1!{x;p;};${x;p;}' $APP/templates/admin.html && \
        sed -i -e "/Linuxserver.io/,+3d" \
        -e "s/commit/calibreweb_version/" $APP/templates/admin.html
}

replacer && echo "Files patched" || echo "Oh fuck what just happened??"
