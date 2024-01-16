#! /bin/bash

set -eu

if [ -z $DOCKER_BUILD_PATH ]; then
    DOCKER_BUILD_PATH=$WORKING_DIRECTORY
fi

echo "Building image"

docker buildx build -t "$ECR_REGISTRY/$ECR_REPO_NAME:latest" -t "$ECR_REGISTRY/$ECR_REPO_NAME:$GITHUB_SHA"\
  --file "$DOCKER_BUILD_PATH"/"$DOCKERFILE" \
  --compress \
  --output type=registry,oci-mediatypes=true,force-compression=true "$DOCKER_BUILD_PATH"

if [ ${CONTAINER_SIGN_KMS_KEY_ARN} != "none" ]; then
    cosign sign --key "awskms:///${CONTAINER_SIGN_KMS_KEY_ARN}" "$ECR_REGISTRY/$ECR_REPO_NAME:$GITHUB_SHA"
fi