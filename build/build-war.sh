#!/bin/bash -e

export ARTIFACT_NAME=$1
export BUILD_ID="ci-${TRAVIS_BUILD_NUMBER}"
export DOCKER_TARGET="${ECR_REPO}/${ARTIFACT_NAME}:${BUILD_ID}"
ARTIFACT_DEST_PATH="/opt/tomcat/webapps/"

find ${DOCKER_BUILD_DIR}

cp ci-tools/build/Dockerfile ${DOCKER_BUILD_DIR}/Dockerfile
sed -i -e "s|BASEIMAGE|${ECR_REPO}/${BASE_IMAGE}|g" ${DOCKER_BUILD_DIR}/Dockerfile
docker build --build-arg name=${ARTIFACT_NAME} --build-arg artifact_destination=${ARTIFACT_DEST_PATH} -t ${DOCKER_TARGET} ${DOCKER_BUILD_DIR}

docker images
