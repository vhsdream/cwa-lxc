#! /usr/bin/env bash

# dirty install script for Calibre-Web Automated
# done over top of a Calibre-Web install via Proxmox Helper Script
# Author: vhsdream

# stop Calibre-web
systemctl stop cps
# install deps
apt-get update && \
apt-get install -y --no-install-recommends \
  build-essential \
  git \
  libldap2-dev \
  libsasl2-dev \
  ghostscript \
  libldap-2.5-0 \
  libmagic1 \
  libsasl2-2 \
  libxi6 \
  libxslt1.1 \
  python3-venv \
  xdg-utils \
  inotify-tools \
  sqlite3 \

# get CWA release
cd /opt
RELEASE=$(curl -s https://api.github.com/repos/vhsdream/cwa-lxc/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
wget -q "https://github.com/vhsdream/cwa-lxc/archive/refs/tags/V${RELEASE}.zip"
unzip -q V${RELEASE}.zip
mv Calibre-Web-Automated-${RELEASE} /opt/cwa
cd /opt/cwa

# creating dirs, according to setup-cwa.sh and the cwa-init s6 script (with some changes for compatibility)
mkdir -p /opt/cwa/metadata_change_logs /opt/cwa/metadata_temp /opt/cwa-book-ingest
mkdir -p /var/lib/cwa/processed_books/converted
mkdir -p /var/lib/cwa/processed_books/imported
mkdir -p /var/lib/cwa/processed_books/failed
mkdir -p /var/lib/cwa/processed_books/fixed_originals
mkdir -p /var/lib/cwa/log_archive
mkdir -p /var/lib/cwa/.cwa_conversion_tmp
# the 'calibre-library' is simply the /opt/calibre-web dir so no need to change
 
# install additional reqs for CWA
pip install -r requirements.txt

# copy modified calibre-web files from CWA
cp -r /opt/cwa/root/app/calibre-web/cps/* /usr/local/lib/python3.11/dist-packages/calibreweb/cps

# At this point I think a number of systemd service files need to be created for the various CWA workers. It is a TODO.
#

cat <<EOF >/etc/systemd/system/cwa-autolibrary.service
[Unit]
Description=Calibre-Web Automated Auto-Library Service
After=network.target cps.service

[Service]
Type=simple
WorkingDirectory=/opt/cwa
ExecStart=/usr/bin/python3 /opt/cwa/scripts/auto_library.py
TimeoutStopSec=10
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/cwa-ingester.service
[Unit]
Description=Calibre-Web Automated Ingest Service
After=network.target cps.service cwa-autolibrary.service

[Service]
Type=simple
WorkingDirectory=/opt/cwa
ExecStart=/usr/bin/bash -c /opt/cwa/scripts/ingest-service.sh
TimeoutStopSec=10
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/cwa-change-detector.service
[Unit]
Description=Calibre-Web Automated Metadata Change Detector Service
After=network.target cps.service cwa-autolibrary.service

[Service]
Type=simple
WorkingDirectory=/opt/cwa
ExecStart=/usr/bin/bash -c /opt/cwa/scripts/change-detector.sh
TimeoutStopSec=10
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
# Then, maybe after all that is done, we restart the Calibre-web service
systemctl start cps
# Then enable the other services
systemctl enable --now cwa-autolibrary cwa-ingester cwa-change-detector

# then cleanup etc etc
