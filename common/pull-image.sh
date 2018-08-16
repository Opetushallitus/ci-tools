#!/bin/bash -e

export IMAGE_NAME="${1:-$BASE_IMAGE}"

docker pull $ECR_REPO/$IMAGE_NAME
