#!/bin/bash -e

export ARTIFACT_NAME=$1
export ECR_REPO="190073735177.dkr.ecr.eu-west-1.amazonaws.com/utility"
export DOCKER_TARGET="${ECR_REPO}/${ARTIFACT_NAME}:${TRAVIS_BUILD_NUMBER}"
export DOCKER_BUILD_DIR="/tmp/docker_build"

rm -rf ${DOCKER_BUILD_DIR}/target
mkdir -p ${DOCKER_BUILD_DIR}/target/config
mkdir -p ${DOCKER_BUILD_DIR}/target/wars
mkdir -p ${DOCKER_BUILD_DIR}/target/jars

cp ci-tools/build/Dockerfile ${DOCKER_BUILD_DIR}/target/
sed -i -e "s|BASEIMAGE|${ECR_REPO}/${BASE_IMAGE}|g" ${DOCKER_BUILD_DIR}/target/Dockerfile
cp ci-tools/run/run-fatjar.sh ${DOCKER_BUILD_DIR}/target/run

docker build --build-arg name=${ARTIFACT_NAME} -t ${DOCKER_TARGET} ${DOCKER_BUILD_DIR}/target
docker images
docker push ${DOCKER_TARGET}
