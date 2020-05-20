#!/usr/bin/env sh
. /etc/os-release
case "$ID" in
alpine) PACKAGES=$(apk info -v | sort) ;;
ubuntu) PACKAGES=$(apt list --installed | awk '{ print $1, $2 }' | sort) ;;
esac

echo "$PACKAGES" >/repository/package-versions && chmod 755 /repository/package-versions
echo "$ID" > /repository/distro && chmod 755 /repository/distro
