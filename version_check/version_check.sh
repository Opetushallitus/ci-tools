#!/usr/bin/env bash
set -eo pipefail

if [ "${TRAVIS_EVENT_TYPE}" = "cron" ]
then
  docker run -v ${TRAVIS_BUILD_DIR}:/repository ${DOCKER_TARGET} /bin/sh -c "apk info -v | sort > /repository/package-versions && chmod 755 /repository/package-versions"
  git diff ${TRAVIS_BUILD_DIR}/package-versions
  git checkout ${TRAVIS_BRANCH}
  sudo apt-get update
  sudo apt-get install -y python3 python3-pip python3-setuptools
  sudo pip3 install -r $(dirname $0)/requirements.txt
  python3 $(dirname $0)/version_check.py
else
  echo "Version check skipped (non scheduled build)"
fi