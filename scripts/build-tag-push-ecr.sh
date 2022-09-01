#! /bin/bash

set -e

echo "building image(s)"
echo 'current dir =' $(pwd)
firstdir=$(pwd)
count=1
while [ $count -le 3 ]
do
  cd "${firstdir}"
  working_dir="WORKING_DIRECTORY_$count"
  ecr_repo_name="ECR_REPO_NAME_$count"
  artifact_bucket_name="ARTIFACT_BUCKET_NAME_$count"
  template_file="TEMPLATE_FILE_$count"

  if [ "${!working_dir}" != "none" ]; then
    cd ${!working_dir}
    echo "Packaging app from ${!working_dir}"

    docker build -t $ECR_REGISTRY/${!ecr_repo_name}:$GITHUB_SHA .
    docker push $ECR_REGISTRY/${!ecr_repo_name}:$GITHUB_SHA
    cosign sign --key awskms:///${CONTAINER_SIGN_KMS_KEY_ARN} $ECR_REGISTRY/${!ecr_repo_name}:$GITHUB_SHA

    sam package --template-file="${!template_file}" --s3-bucket="${!artifact_bucket_name}" --output-template-file=cf-template.yaml

    sed -i "s|CONTAINER-IMAGE-PLACEHOLDER|$ECR_REGISTRY/${!ecr_repo_name}:$GITHUB_SHA|" cf-template.yaml
    zip template.zip cf-template.yaml
    aws s3 cp template.zip "s3://${!artifact_bucket_name}/template.zip" --metadata "repository=$GITHUB_REPOSITORY,commitsha=$GITHUB_SHA"
  fi
  count=$((count+1))
done