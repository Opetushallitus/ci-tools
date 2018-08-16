#!/bin/bash

sudo pip install awscli

eval $(aws ecr get-login --no-include-email --region eu-west-1)
