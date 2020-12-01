#!/bin/bash
set -eou pipefail

. /etc/os-release
case "$ID" in
alpine) PACKAGES=$(apk info -v | sort) ;;
ubuntu) PACKAGES=$(apt list --installed | awk '{ print $1, $2 }' | sort)
        NGINX=$(apt list --upgradeable nginx-extras || true | grep -v Listing...)
;;
esac

UPDATED=$(diff /repository/package-versions <(echo "$PACKAGES") || true)

if [[ -n "${UPDATED}" ]]; then
  echo "${UPDATED}" | grep ">"  | awk -F'[ /]' '{ print $2, $4 }' >  /repository/updated-packages
  chmod 755 /repository/updated-packages
fi

echo "$PACKAGES" >/repository/package-versions && chmod 755 /repository/package-versions
echo "$ID" > /repository/distro && chmod 755 /repository/distro

if [[ -n "${NGINX}" ]]; then
   NGINX=$(echo "${NGINX}" | awk -F'[ /\]]' '{ print "ngingx-extras needs to be manually udpated from version", $7, "to version", $3 }')
   echo "${NGINX}" > /repository/nginx-updates && chmod 755 /repository/nginx-updates
fi

