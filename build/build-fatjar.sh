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
docker push ${DOCKER_TARGET}

export BUILD_TIMESTAMP=`TZ='Europe/Helsinki' date +'%Y-%m-%d %H:%M:%S %Z'`
aws dynamodb put-item --table-name builds --item "{\"Service\": {\"S\": \"${ARTIFACT_NAME}\"}, \"Build\": {\"S\": \"${BUILD_ID}\"}, \"Branch\": {\"S\": \"${TRAVIS_BRANCH}\"}, \"Commit\": {\"S\": \"${TRAVIS_COMMIT}\"}, \"Time\": {\"S\": \"${BUILD_TIMESTAMP}\"}}" --condition-expression "attribute_not_exists(Id)" --region eu-west-1

# Clean build dir to prevent mixing builds in multi-artifact repositories
./ci-tools/common/clean-docker-build-dir.sh
