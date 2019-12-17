#!/bin/bash -e

if [ "${TRAVIS_EVENT_TYPE}" = "cron" ]
then
  echo "Image push skipped (scheduled build)"
else

  export ARTIFACT_NAME=$1
  export BUILD_ID="ci-${TRAVIS_BUILD_NUMBER}"
  export DOCKER_TARGET="${ECR_REPO}/${ARTIFACT_NAME}:${BUILD_ID}"

  echo "Checking that build metadata must not already exist with build ID ${BUILD_ID}."
  PREVIOUS_BUILD=$(aws dynamodb get-item --table-name builds --key "{\"Service\": {\"S\": \"$ARTIFACT_NAME\"}, \"Build\": {\"S\": \"$BUILD_ID\"}}" --output json --region eu-west-1)
  PREVIOUS_BUILD_ID=$(echo $PREVIOUS_BUILD|jq -r ".Item.Build.S")

  if [[ $PREVIOUS_BUILD_ID == $BUILD_ID ]]; then
    echo "Found existing build with same ID, this seems to be a rebuild!"
    echo "Do NOT click the 'Restart build' button in Travis CI under a previous build."
    echo "Either git push a new commit, or select 'Trigger build'."
    echo "Overwriting existing images it no allowed."
    exit 2
  else
    echo "Uploading Docker image ${DOCKER_TARGET} to repository"
    docker push ${DOCKER_TARGET}

    if [ $# -eq 2 ]; then
      ADDITIONAL_TAG=$2
      ADDITIONAL_TARGET="${ECR_REPO}/${ARTIFACT_NAME}:${ADDITIONAL_TAG}"
      echo "Adding additional tag $ADDITIONAL_TAG"
      docker tag ${DOCKER_TARGET} ${ADDITIONAL_TARGET}
      docker push ${ADDITIONAL_TARGET}
    fi

    export BASEIMAGE_TYPE=$(docker inspect ${DOCKER_TARGET} --format="{{ .ContainerConfig.Labels.BaseimageType }}")
    export BASEIMAGE_BUILDNUMBER=$(docker inspect ${DOCKER_TARGET} --format="{{ .ContainerConfig.Labels.BaseimageBuildNumber }}")
    export BASEIMAGE_BUILDTIME=$(docker inspect ${DOCKER_TARGET} --format="{{ .ContainerConfig.Labels.BaseimageBuildTime }}")

    echo "Updating build metadata to DynamoDB"
    export BUILD_TIMESTAMP=`TZ='Europe/Helsinki' date +'%Y-%m-%d %H:%M:%S %Z'`
    aws dynamodb put-item --table-name builds --item "{\"Service\": {\"S\": \"${ARTIFACT_NAME}\"}, \"Build\": {\"S\": \"${BUILD_ID}\"}, \"Branch\": {\"S\": \"${TRAVIS_BRANCH}\"}, \"Commit\": {\"S\": \"${TRAVIS_COMMIT}\"}, \"Time\": {\"S\": \"${BUILD_TIMESTAMP}\"}, \"BaseimageType\": {\"S\": \"${BASEIMAGE_TYPE}\"}, \"BaseimageBuildNumber\": {\"S\": \"${BASEIMAGE_BUILDNUMBER}\"}, \"BaseimageBuildTime\": {\"S\": \"${BASEIMAGE_BUILDTIME}\"}}" --condition-expression "attribute_not_exists(Id)" --region eu-west-1

    echo "Finished uploading image"

  fi
fi