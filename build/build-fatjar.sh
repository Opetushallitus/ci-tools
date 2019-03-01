#!/bin/bash -e

export ARTIFACT_NAME=$1
export BUILD_ID="ci-${TRAVIS_BUILD_NUMBER}"
export DOCKER_TARGET="${ECR_REPO}/${ARTIFACT_NAME}:${BUILD_ID}"
ARTIFACT_DEST_PATH="/root"

find ${DOCKER_BUILD_DIR}

if [[ $BASE_IMAGE == *"jdk11"* ]]; then
    echo "Using run script from base image"
    cp ci-tools/build/Dockerfile ${DOCKER_BUILD_DIR}/Dockerfile
    sed -i -e "s|BASEIMAGE|${ECR_REPO}/${BASE_IMAGE}|g" ${DOCKER_BUILD_DIR}/Dockerfile
    docker build --build-arg name=${ARTIFACT_NAME} --build-arg artifact_destination=${ARTIFACT_DEST_PATH} -t ${DOCKER_TARGET} ${DOCKER_BUILD_DIR}
else
    echo "Copying legacy run script into docker image"
    LEGACY_PATH="ci-tools/build/PP-413_run_scripts_for_old_baseimages"
    cp $LEGACY_PATH/Dockerfile-fatjar-run-from-ci-tools ${DOCKER_BUILD_DIR}/Dockerfile
    cp $LEGACY_PATH/run/run-fatjar.sh ${DOCKER_BUILD_DIR}/run
    sed -i -e "s|BASEIMAGE|${ECR_REPO}/${BASE_IMAGE}|g" ${DOCKER_BUILD_DIR}/Dockerfile
    docker build --build-arg name=${ARTIFACT_NAME} -t ${DOCKER_TARGET} ${DOCKER_BUILD_DIR}
fi

docker images
