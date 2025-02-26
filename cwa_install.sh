#! /usr/bin/env bash

# Dirty install script for Calibre-Web Automated
# Done over top of a Calibre-Web install via Proxmox Helper Script
# https://github.com/community-scripts/ProxmoxVE/blob/main/install/calibre-web-install.sh
# Author: vhsdream 2025
# USE AT YOUR OWN RISK
# AFTER RUNNING THIS SCRIPT IT'S LIKELY YOU CAN NO LONGER USE THE 'update' FUNCTION
# FROM Proxmox Helper Scripts

set -euo pipefail

# give warning
echo "This script only works if Calibre-Web was installed with the Proxmox Helper Script" && sleep 3
echo "If it succeeds, you can no longer use the 'update' function from Proxmox Helper Scripts" && sleep 3
echo "Run this script at your own risk. I TAKE NO RESPONSIBILITY FOR DATA LOSS!" && sleep 3
echo "You have 5 seconds to cancel before the script proceeds..." && sleep 6

# stop Calibre-web
echo "Stopping Calibre-Web service & installing CWA dependencies..." && sleep 1
systemctl disable -q --now cps
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

echo "Dependencies installed." && sleep 2
# get CWA fork with modified scripts
echo "Cloning Calibre-Web Automated & switching to latest release branch..." && sleep 1
cd /opt
RELEASE=$(curl -s https://api.github.com/repos/crocodilestick/Calibre-Web-Automated/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
git clone https://github.com/crocodilestick/Calibre-Web-Automated.git /opt/cwa --single-branch &>/dev/null
git checkout V${RELEASE} &>/dev/null
cd /opt/cwa
echo "Repo ready." && sleep 1

# install additional reqs for CWA
echo "Installing Python requirements for CWA..." && sleep 1
pip install -r requirements.txt -qqq
echo "Installed." && sleep 2

# Install git patch file
echo "Applying git patch for Proxmox LXC compatibility..." && sleep 1
# Patch will likely need to be downloaded from somewhere
# wget -q https://github-location-of-patch.patch
wget -q https://raw.githubusercontent.com/vhsdream/cwa-lxc/refs/heads/git-patch/proxmox-lxc.patch -O /opt/proxmox-lxc.patch
git apply /opt/proxmox-lxc.patch &>/dev/null

# creating dirs, according to setup-cwa.sh and the cwa-init s6 script (with some changes for compatibility)
echo "Creating required directories for CWA..." && sleep 1
mkdir -p /opt/cwa/metadata_change_logs /opt/cwa/metadata_temp /opt/cwa-book-ingest
mkdir -p /var/lib/cwa/processed_books/converted
mkdir -p /var/lib/cwa/processed_books/imported
mkdir -p /var/lib/cwa/processed_books/failed
mkdir -p /var/lib/cwa/processed_books/fixed_originals
mkdir -p /var/lib/cwa/log_archive
mkdir -p /var/lib/cwa/.cwa_conversion_tmp
# the 'calibre-library' is simply the /opt/calibre-web dir so no need to change
 
# copy modified calibre-web files from CWA
echo "Copying patched Calibre-Web files to local Python lib folder..." && sleep 1
cp -r /opt/cwa/root/app/calibre-web/cps/* /usr/local/lib/python3.11/dist-packages/calibreweb/cps

# Create service files for CWA workers
echo "Creating CWA worker service files..." && sleep 1
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

cat <<EOF >/etc/systemd/system/cwa.target
[Unit]
Description=Calibre-Web Automated Services
After=network-online.target
Wants=cps.service cwa-autolibrary.service cwa-ingester.service cwa-change-detector.service

[Install]
WantedBy=multi-user.target
EOF
echo "Service files created." && sleep 1

# Enable CWA Service target
echo "Enabling & starting services via cwa.target..." && sleep 1
systemctl daemon-reload
systemctl enable -q --now cwa.target
echo "CWA started! (hopefully)" && sleep 1

# then cleanup etc etc
echo "Cleaning up..." && sleep 1
apt autoremove - y &>/dev/null && apt autoclean -y &>/dev/null
echo "Done!"
