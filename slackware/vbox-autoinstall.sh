#!/bin/bash
#
# Copyright (c) 2018 Cristiano Urban (https://crish4cks.net)
#
# IMPORTANT!!!
# THIS SCRIPT IS STILL IN TESTING PHASE, SO USE IT AT YOUR OWN RISK!
#
# A simple bash script to automatically install/update/uninstall
# the Oracle VirtualBox binary (.run) and the respective extension
# pack on Slackware
#
#
# Examples of usage (as root):
#
# 1) Install the latest version of VirtualBox
# curl https://raw.githubusercontent.com/crish4cks/Bash/master/vbox-autoinstall | sh
#
# 2) Install the latest stable version of VirtualBox by passing the BRANCH parameter
# curl https://raw.githubusercontent.com/crish4cks/Bash/master/vbox-autoinstall | BRANCH=stable sh
#
# 3) Install the latest beta version of VirtualBox by passing the BRANCH parameter
# curl https://raw.githubusercontent.com/crish4cks/Bash/master/vbox-autoinstall | BRANCH=beta sh
#
#
# Version 0.2
#

DIALOG_TITLE="VirtualBox Binary Installer"
BASE_URL="https://download.virtualbox.org/virtualbox"

# Check the BRANCH parameter
if [ "$BRANCH" == "stable" ]; then
  BRANCH="LATEST-STABLE.TXT"
elif [ "$BRANCH" == "beta" ]; then
  BRANCH="LATEST-BETA.TXT"
elif [ -z "$BRANCH" ]; then
  BRANCH="LATEST.TXT"
else
  dialog --backtitle "${DIALOG_TITLE}" \
         --clear \
         --msgbox "\nThe BRANCH parameter you passed is not valid! \n\nPlease, choose between [stable] and [beta], or leave it empty." 10 58
    exit
fi

VERSION=$(curl -s ${BASE_URL}/${BRANCH})
EXT_PACK=$(curl -s ${BASE_URL}/${VERSION}/ | grep -Po '(?<=href=")[^"]*' | egrep ${VERSION}.vbox-extpack)
GUEST_ADDITIONS=$(curl -s ${BASE_URL}/${VERSION}/ | grep -Po '(?<=href=")[^"]*' | egrep GuestAdditions)

# First installation flag
FLAG=0

# Temporary work dir
TMP=${TMP:-/tmp/vbox-${VERSION}}
mkdir -p $TMP

# Determine the system architecture
if [ -z "$ARCH" ]; then
  case "$( uname -m )" in
    i?86) ARCH=i586 ;;
       *) ARCH=$( uname -m ) ;;
  esac
fi

# Set the vbox arch variable
if [[ "$ARCH" != "x86_64" ]]; then
  VBOX_ARCH="x86"
else
  VBOX_ARCH="amd64"
fi

# Find the right binary name
VBOX_BINARY=$(curl -s ${BASE_URL}/${VERSION}/ | grep -Po '(?<=href=")[^"]*' | egrep ${VBOX_ARCH}.run)


# Downlad all the stuff
function download () {
  dialog --backtitle "${DIALOG_TITLE}" \
         --infobox "\n\nDownloading all the files..." 7 33
  sleep 2

  wget -nc ${BASE_URL}/${VERSION}/${VBOX_BINARY} -P $TMP
  wget -nc ${BASE_URL}/${VERSION}/${EXT_PACK} -P $TMP
  wget -nc ${BASE_URL}/${VERSION}/${GUEST_ADDITIONS} -P $TMP

  dialog --backtitle "${DIALOG_TITLE}" \
         --clear \
         --msgbox "\n\nDownload completed." 10 25
}

# Install all the stuff
# TODO: guest additions
function install_all () {
  INSTALLED_VERSION=$((VBoxManage --version | cut -d r -f 1) 2> /dev/null)

  if [ -z "$INSTALLED_VERSION" ]; then
    FLAG=1
    dialog --backtitle "${DIALOG_TITLE}" \
           --clear \
           --yesno "\nVirtualBox-${VERSION} will be installed on your system.\n\nDo you want to proceed?" 10 40

    case $? in
      0)
        :;;
      1)
        exit;;
      255)
        ;;
    esac
  else
    dialog --backtitle "${DIALOG_TITLE}" \
           --clear \
           --msgbox "\nVirtualBox is already installed on your system! \n\nPlease, select the [update] option in the main menu instead." 10 58
    exit
  fi

  set -e
  clean_tmp_dir
  download
  # Install the binary (.run)
  dialog --backtitle "${DIALOG_TITLE}" \
         --infobox "\n\nInstalling 'VirtualBox'..." 7 30
  sleep 2
  bash ${TMP}/${VBOX_BINARY}
  # Install the extension pack (.vbox-extpack)
  dialog --backtitle "${DIALOG_TITLE}" \
         --infobox "\n\nInstalling 'Extension Pack'..." 7 37
  # Accept the license automatically
  yes | VBoxManage extpack install --replace ${TMP}/${EXT_PACK}
  set +e

  if [ "$FLAG" -ne "0" ]; then
    dialog --backtitle "${DIALOG_TITLE}" \
           --clear \
           --msgbox "\n\nVirtualBox has been successfully installed!" 10 48
  fi
}

# Update
function update () {
  INSTALLED_VERSION=$((VBoxManage --version | cut -d r -f 1) 2> /dev/null)

  if [ -z "$INSTALLED_VERSION" ]; then
    dialog --backtitle "${DIALOG_TITLE}" \
           --clear \
           --msgbox "\nVirtualBox is not installed on your system! \n\nPlease, select the [install] option in the main menu instead." 10 58
    exit
  fi

  if [ "$INSTALLED_VERSION" != "${VERSION}" ]; then
    dialog --backtitle "${DIALOG_TITLE}" \
           --clear \
           --yesno "\nNew stable version found: VirtualBox-${VERSION}\n\nDo you want to proceed?" 10 32

    case $? in
      0)
        set -e
        clean_tmp_dir
        download
        # Update the binary (.run)
        dialog --backtitle "${DIALOG_TITLE}" \
               --infobox "\n\nUpdating 'VirtualBox'..." 7 28
        sleep 2
        bash ${TMP}/${VBOX_BINARY}
        # Update the extension pack (.vbox-extpack)
        dialog --backtitle "${DIALOG_TITLE}" \
               --infobox "\n\nUpdating 'Extension Pack'..." 7 33
        # Accept the license automatically
        yes | VBoxManage extpack install --replace ${TMP}/${EXT_PACK}
        ;;
      1)
        exit;;
      255)
    esac
  else
    dialog --backtitle "${DIALOG_TITLE}" \
           --clear \
           --msgbox "\n\nNo updates available." 10 28
    exit
  fi

  dialog --backtitle "${DIALOG_TITLE}" \
         --clear \
         --msgbox "\n\nVirtualBox has been successfully updated!" 10 45
}

# Uninstall
function uninstall () {
  INSTALLED_VERSION=$((VBoxManage --version | cut -d r -f 1) 2> /dev/null)

  dialog --backtitle "${DIALOG_TITLE}" \
         --clear \
         --yesno "\n\nAre you sure you want to remove VirtualBox from your system?" 10 37

  case $? in
    0)
      :;;
    1)
      exit;;
    255)
  esac

  if [ -z "$INSTALLED_VERSION" ]; then
    dialog --backtitle "${DIALOG_TITLE}" \
           --clear \
           --msgbox "\n\nVirtualBox is not installed on your system!" 10 48
    exit
  else
    set -e
    # Download the .run binary of the currently installed version, if not present
    wget -nc ${BASE_URL}/${INSTALLED_VERSION}/${VBOX_BINARY} -P $TMP
    bash ${TMP}/${VBOX_BINARY} uninstall
    clean_all
    set +e

    dialog --backtitle "${DIALOG_TITLE}" \
           --clear \
           --msgbox "\n\nVirtualBox has been removed from your system." 10 50
  fi
}

# Remove the content of temporary dir
function clean_tmp_dir () {
  rm -rf $TMP/*
}

# Completely remove the temporary dir
function clean_all () {
  rm -rf $TMP
}

# Initial menu
  exec 3>&1
  selection=$(dialog \
    --backtitle "${DIALOG_TITLE}" \
    --clear \
    --cancel-label "Exit" \
    --menu "\nPlease select an option:" \
    12 42 3 \
    "1" "Perform a fresh installation" \
    "2" "Update to a new version" \
    "3" "Uninstall the current version" \
    2>&1 1>&3)
  exit_status=$?
exec 3>&-

case $exit_status in
  0)
    :;;
  1)
    exit;;
  255)
      ;;
esac

case $selection in
  1)
    install_all;;
  2)
    update;;
  3)
    uninstall;;
esac
