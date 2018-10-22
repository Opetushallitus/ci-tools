#!/bin/bash -e

export ARTIFACT_NAME=$1
export BUILD_ID="ci-${TRAVIS_BUILD_NUMBER}"
export DOCKER_TARGET="${ECR_REPO}/${ARTIFACT_NAME}:${BUILD_ID}"

echo "Uploading Docker image ${DOCKER_TARGET} to repository"
docker push ${DOCKER_TARGET}

if [ $# -eq 2 ]; then
  ADDITIONAL_TAG=$2
  ADDITIONAL_TARGET="${ECR_REPO}/${ARTIFACT_NAME}:${ADDITIONAL_TAG}"
  echo "Adding additional tag $ADDITIONAL_TAG"
  docker tag ${DOCKER_TARGET} ${ADDITIONAL_TARGET}
  docker push ${ADDITIONAL_TARGET}
fi

echo "Updating build metadata to DynamoDB"
export BUILD_TIMESTAMP=`TZ='Europe/Helsinki' date +'%Y-%m-%d %H:%M:%S %Z'`
aws dynamodb put-item --table-name builds --item "{\"Service\": {\"S\": \"${ARTIFACT_NAME}\"}, \"Build\": {\"S\": \"${BUILD_ID}\"}, \"Branch\": {\"S\": \"${TRAVIS_BRANCH}\"}, \"Commit\": {\"S\": \"${TRAVIS_COMMIT}\"}, \"Time\": {\"S\": \"${BUILD_TIMESTAMP}\"}}" --condition-expression "attribute_not_exists(Id)" --region eu-west-1

echo "Finished uploading image"
