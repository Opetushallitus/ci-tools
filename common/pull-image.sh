#!/bin/bash

export IMAGE_NAME="${1:-$BASE_IMAGE}"
export ECR_REPO="190073735177.dkr.ecr.eu-west-1.amazonaws.com/utility"

docker pull $ECR_REPO/$IMAGE_NAME
