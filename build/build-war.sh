#!/bin/bash -e

export ARTIFACT_NAME=$1
export BUILD_ID="ci-${TRAVIS_BUILD_NUMBER}"
export DOCKER_TARGET="${ECR_REPO}/${ARTIFACT_NAME}:${BUILD_ID}"
ARTIFACT_DEST_PATH="/opt/tomcat/webapps/"

find ${DOCKER_BUILD_DIR}

if [[ $BASE_IMAGE != *"base-legacy"* ]]; then
    echo "Using run script from base image"
    cp ci-tools/build/Dockerfile ${DOCKER_BUILD_DIR}/Dockerfile
    sed -i -e "s|BASEIMAGE|${ECR_REPO}/${BASE_IMAGE}|g" ${DOCKER_BUILD_DIR}/Dockerfile
    docker build --build-arg name=${ARTIFACT_NAME} --build-arg artifact_destination=${ARTIFACT_DEST_PATH} -t ${DOCKER_TARGET} ${DOCKER_BUILD_DIR}
else
    echo "Warning: You are using the deprecated base-legacy image. Update your .travis.yml to use a new baseimage."
    LEGACY_PATH="ci-tools/build/PP-413_run_scripts_for_old_baseimages"
    cp $LEGACY_PATH/Dockerfile-war-run-from-ci-tools ${DOCKER_BUILD_DIR}/Dockerfile
    cp $LEGACY_PATH/run/run-war.sh ${DOCKER_BUILD_DIR}/run
    sed -i -e "s|BASEIMAGE|${ECR_REPO}/${BASE_IMAGE}|g" ${DOCKER_BUILD_DIR}/Dockerfile
    docker build --build-arg name=${ARTIFACT_NAME} -t ${DOCKER_TARGET} ${DOCKER_BUILD_DIR}
fi

docker images
