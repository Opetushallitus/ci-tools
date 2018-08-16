#!/bin/bash -e

export ARTIFACT_NAME=$1
export DOCKER_TARGET="${ECR_REPO}/${ARTIFACT_NAME}:${TRAVIS_BUILD_NUMBER}"

cp ci-tools/build/Dockerfile-fatjar ${DOCKER_BUILD_DIR}/Dockerfile
sed -i -e "s|BASEIMAGE|${ECR_REPO}/${BASE_IMAGE}|g" ${DOCKER_BUILD_DIR}/Dockerfile
cp ci-tools/run/run-fatjar.sh ${DOCKER_BUILD_DIR}/run

docker build --build-arg name=${ARTIFACT_NAME} -t ${DOCKER_TARGET} ${DOCKER_BUILD_DIR}
find ${DOCKER_BUILD_DIR}
docker images
docker push ${DOCKER_TARGET}

# Clean build dir to prevent mixing builds in multi-artifact repositories
./ci-tools/common/clean-docker-build-dir.sh
