#!/bin/bash -e

export ARTIFACT_NAME=$1
export BUILD_ID="ci-${TRAVIS_BUILD_NUMBER}"
export DOCKER_TARGET="${ECR_REPO}/${ARTIFACT_NAME}:${BUILD_ID}"

cp ci-tools/build/Dockerfile-fatjar ${DOCKER_BUILD_DIR}/Dockerfile
sed -i -e "s|BASEIMAGE|${ECR_REPO}/${BASE_IMAGE}|g" ${DOCKER_BUILD_DIR}/Dockerfile
cp ci-tools/run/run-fatjar.sh ${DOCKER_BUILD_DIR}/run

find ${DOCKER_BUILD_DIR}
docker build --build-arg name=${ARTIFACT_NAME} -t ${DOCKER_TARGET} ${DOCKER_BUILD_DIR}
docker images
