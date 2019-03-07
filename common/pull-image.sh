#!/bin/bash -e

export IMAGE_NAME="${1:-$BASE_IMAGE}"

# PP-418 Deprecate base-legacy
if [[ $IMAGE_NAME == *"base-legacy"* ]]; then
    echo "Error: You are using the deprecated base-legacy image. Update your .travis.yml to use a new baseimage."
    echo "Use any one of the following:"
    echo 'export BASE_IMAGE="baseimage-fatjar:master"'
    echo 'export BASE_IMAGE="baseimage-fatjar:jdk11"'
    echo 'export BASE_IMAGE="baseimage-war:master"'
    echo 'export BASE_IMAGE="baseimage-war:jdk11"'
    echo "Example: https://github.com/Opetushallitus/yki/blob/08a3577c20a6d172b4dbdb5bc8031ca739fd80b6/.travis.yml#L28"
    travis_terminate 1 # This will break the build
else
    docker pull $ECR_REPO/$IMAGE_NAME
fi
