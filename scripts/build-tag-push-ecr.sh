#! /bin/bash

set -eu

if [ -z $DOCKER_BUILD_PATH ]; then
    DOCKER_BUILD_PATH=$WORKING_DIRECTORY
fi

echo "Building image"
docker buildx create \
  --name zstd-builder \
  --driver docker-container \
  --driver-opt image=moby/buildkit:v0.12.4
docker buildx use zstd-builder
#docker buildx build \
#  --file "$DOCKER_BUILD_PATH"/"$DOCKERFILE" \
#  --output type=image,name="$ECR_REGISTRY/$ECR_REPO_NAME:$GITHUB_SHA",oci-mediatypes=true,compression=zstd,compression-level=3,force-compression=true,push=true "$DOCKER_BUILD_PATH"

docker buildx build -t "$ECR_REGISTRY/$ECR_REPO_NAME:latest" -t "$ECR_REGISTRY/$ECR_REPO_NAME:$GITHUB_SHA"\
  --squash \
  --file "$DOCKER_BUILD_PATH"/"$DOCKERFILE" \
  --output type=registry,oci-mediatypes=true,compression=zstd,compression-level=3,force-compression=true "$DOCKER_BUILD_PATH"

if [ ${CONTAINER_SIGN_KMS_KEY_ARN} != "none" ]; then
    cosign sign --key "awskms:///${CONTAINER_SIGN_KMS_KEY_ARN}" "$ECR_REGISTRY/$ECR_REPO_NAME:$GITHUB_SHA"
fi