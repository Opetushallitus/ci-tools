#!/bin/bash -e

# These environment variables will be available during the whole build as this
# file will be sourced.
export DOCKER_BUILD_DIR="/tmp/docker_build"
export ECR_REPO="190073735177.dkr.ecr.eu-west-1.amazonaws.com/utility"

# Log used ci-tools version
git -C ci-tools/ log -1

sudo pip install awscli

eval $(aws ecr get-login --no-include-email --region eu-west-1)

# Force Travis to use public address of artifactory
sudo sh -c "printf '\n%s artifactory.oph.ware.fi\n' $(dig +short artifactory.opintopolku.fi|head -n1) >> /etc/hosts"

./ci-tools/common/clean-docker-build-dir.sh
