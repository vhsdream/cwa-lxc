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

# /opt/cwa/dirs.json
OLD_INGEST="/cwa-book-ingest"
NEW_INGEST="/opt/cwa-book-ingest"
OLD_LIBRARY="/calibre-library"
NEW_LIBRARY="/opt/calibre-web"
OLD_CONVERSION_DIR="$OLD_CONFIG/.cwa_conversion_tmp"
NEW_CONVERSION_DIR="$CONFIG/.cwa_conversion_tmp"

# new scripts can be done by cat <<EOFing
