#!/bin/bash

#You will need to enter in the IKEY, SKEY and API Host below to configure it. The Duo Desktop packages must be in the same location as the script by default. This script is specifically designed to work with Datto RMM deployments.
#Download files from: https://duo.com/docs/macos
#Make sure to adjust the version number below if version is different.

version="2.0.3"
echo "Duo Security Mac Logon configuration tool v${version}."

#Search for the MacLogon package in the script directory
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pkgs=( "$script_dir"/MacLogon-NotConfigured-*.pkg )

if [[ ${#pkgs[@]} -ne 1 ]]; then
    echo "Error: Expected one MacLogon package, found ${#pkgs[@]}."
    exit 1
fi

pkg_path="${pkgs[0]}"

if [ ! -f "$pkg_path" ]; then
    echo "No package found at $pkg_path. Exiting."
    exit 1
fi

#Set Duo authentication variables
ikey="updateme"
skey="updateme"
api_hostname="api-XXXXXXX.duosecurity.com"
fail_open="false"
smartcard_bypass="false"
auto_push="true"

pkg_dir=$(dirname "${pkg_path}")
pkg_name=$(basename "${pkg_path}" | awk -F\. '{print $1 "." $2}')
tmp_path="/tmp/${pkg_name}"

echo -e "\nModifying ${pkg_path}...\n"

#Expand package for modification
pkgutil --expand "${pkg_path}" "${tmp_path}"

echo -e "Updating config.plist...\n"

#Apply settings
defaults write "${tmp_path}/Scripts/config.plist" ikey -string "${ikey}"
defaults write "${tmp_path}/Scripts/config.plist" skey -string "${skey}"
defaults write "${tmp_path}/Scripts/config.plist" api_hostname -string "${api_hostname}"
defaults write "${tmp_path}/Scripts/config.plist" fail_open -bool "${fail_open}"
defaults write "${tmp_path}/Scripts/config.plist" smartcard_bypass -bool "${smartcard_bypass}"
defaults write "${tmp_path}/Scripts/config.plist" auto_push -bool "${auto_push}"
defaults write "${tmp_path}/Scripts/config.plist" twofa_unlock -bool false
plutil -convert xml1 "${tmp_path}/Scripts/config.plist"

#Rebuild package
out_pkg="${pkg_dir}/MacLogon-${version}.pkg"
echo -e "Finalizing package as ${out_pkg}\n"
pkgutil --flatten "${tmp_path}" "${out_pkg}"

#Cleanup
echo -e "Cleaning up temp files...\n"
rm -rf "${tmp_path}"

echo -e "Done! The package ${out_pkg} has been configured."

#Install the generated package
echo -e "\nInstalling the configured package...\n"
sudo installer -pkg "${out_pkg}" -target /

if [ $? -eq 0 ]; then
    echo -e "Installation completed successfully."
else
    echo -e "Installation failed."
    exit 1
fi

exit 0
