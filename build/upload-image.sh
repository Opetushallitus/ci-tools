#!/bin/bash -e

export ARTIFACT_NAME=$1
export BUILD_ID="ci-${TRAVIS_BUILD_NUMBER}"
export DOCKER_TARGET="${ECR_REPO}/${ARTIFACT_NAME}:${BUILD_ID}"

echo "Uploading Docker image ${DOCKER_TARGET} to repository"
docker push ${DOCKER_TARGET}

if [ ${TRAVIS_BRANCH} == "master" ]; then
  export MASTER_BRANCH_TAG="${ECR_REPO}/${ARTIFACT_NAME}:latest-master"
  echo "We are in ${TRAVIS_BRANCH} branch, adding extra tag"
  docker tag ${DOCKER_TARGET} ${MASTER_BRANCH_TAG}
  docker push ${MASTER_BRANCH_TAG}
fi

echo "Updating build metadata to DynamoDB"
export BUILD_TIMESTAMP=`TZ='Europe/Helsinki' date +'%Y-%m-%d %H:%M:%S %Z'`
aws dynamodb put-item --table-name builds --item "{\"Service\": {\"S\": \"${ARTIFACT_NAME}\"}, \"Build\": {\"S\": \"${BUILD_ID}\"}, \"Branch\": {\"S\": \"${TRAVIS_BRANCH}\"}, \"Commit\": {\"S\": \"${TRAVIS_COMMIT}\"}, \"Time\": {\"S\": \"${BUILD_TIMESTAMP}\"}}" --condition-expression "attribute_not_exists(Id)" --region eu-west-1

echo "Finished uploading image"
