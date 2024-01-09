#! /bin/bash

set -eu

if [ -z $DOCKER_BUILD_PATH ]; then
    DOCKER_BUILD_PATH=$WORKING_DIRECTORY
fi

echo "Building image"

docker build -t "$ECR_REGISTRY/$ECR_REPO_NAME:$GITHUB_SHA" -t "$ECR_REGISTRY/$ECR_REPO_NAME:latest" -f "$DOCKER_BUILD_PATH"/"$DOCKERFILE" "$DOCKER_BUILD_PATH"
docker push --all-tags "$ECR_REGISTRY/$ECR_REPO_NAME"

if [ ${CONTAINER_SIGN_KMS_KEY_ARN} != "none" ]; then
    cosign sign --key "awskms:///${CONTAINER_SIGN_KMS_KEY_ARN}" "$ECR_REGISTRY/$ECR_REPO_NAME:$GITHUB_SHA"
fi