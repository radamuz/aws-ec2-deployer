#!/bin/bash

export AWS_PAGER="cat"

source .env

export AWS_PROFILE=$1
export AWS_REGION=$2
export AWS_ACCOUNT_ALIAS=$3
export ENTORNO=$4
export NOMBRE_APLICACION=$5
export AWS_ACCOUNT_ID=$6
export DOCKERFILE=$7

if [[ -z "$AWS_REGION" ]]; then
    echo "Error: AWS_REGION está vacío. Pasa la región como argumento o define AWS_REGION en el entorno."
    exit 1
fi


REPOSITORY_URI=$(aws ecr describe-repositories --profile "$AWS_PROFILE" --region "$AWS_REGION" --repository-names ${DOCKERFILE%.Dockerfile} --query 'repositories[0].repositoryUri' --output text)


# Navigate to the repobase directory
cd $REPOBASE_NAME

# Build the Docker image (multi-platform required)
USE_PUSH_AFTER_BUILD=false

if ! docker buildx version >/dev/null 2>&1; then
    echo "Error: Docker Buildx no está disponible. Instala/activa buildx para construir multi-plataforma."
    exit 1
fi

BUILDX_BUILDER_NAME="multi-platform-builder"
if ! docker buildx inspect "$BUILDX_BUILDER_NAME" >/dev/null 2>&1; then
    docker buildx create --name "$BUILDX_BUILDER_NAME" --driver docker-container --use >/dev/null
else
    docker buildx use "$BUILDX_BUILDER_NAME" >/dev/null
fi

docker buildx inspect --bootstrap >/dev/null

aws ecr get-login-password --profile "$AWS_PROFILE" --region "$AWS_REGION" | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

echo docker buildx build --platform linux/arm64 --push -t $REPOSITORY_URI:latest -f $DOCKERFILE .
docker buildx build --platform linux/arm64 --push -t $REPOSITORY_URI:latest -f $DOCKERFILE .
if [[ $? -ne 0 ]]; then
    echo "Error: La construcción de la imagen Docker falló."
    exit 1
fi

# Reset Variables
export AWS_PROFILE=$1
export AWS_REGION=$2
export AWS_ACCOUNT_ID=$6

# Push the Docker image to the ECR registry
# (buildx --push ya publicó el manifest multi-plataforma)

cd -

rm -rf $REPOBASE_NAME
