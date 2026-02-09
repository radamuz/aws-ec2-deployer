#!/bin/bash

# Script variables
export AWS_PAGER="cat"
BUILDX_BUILDER_NAME="multi-platform-builder"
# Fin Script variables

# Parámetros
DOCKERFILE_PATH=$1
# Fin parámetros

# Post parámetros variables
DOCKERFILE_NAME=$(basename "$DOCKERFILE_PATH")
# Fin Post parámetros variables

# Comprobar que docker buildx esté disponible
if ! docker buildx version >/dev/null 2>&1; then
    echo "Error: Docker Buildx no está disponible. Instala/activa buildx para construir multi-plataforma."
    exit 1
fi
# Fin Comprobar que docker buildx esté disponible

# Asegurar construcción multi-plataforma con docker buildx
if ! docker buildx inspect "$BUILDX_BUILDER_NAME" >/dev/null 2>&1; then
    docker buildx create --name "$BUILDX_BUILDER_NAME" --driver docker-container --use >/dev/null
else
    docker buildx use "$BUILDX_BUILDER_NAME" >/dev/null
fi
docker buildx inspect --bootstrap >/dev/null
# Fin Asegurar construcción multi-plataforma con docker buildx

# Asegurarse de que existe la carpeta tars
mkdir -p tars
# Fin Asegurarse de que existe la carpeta tars

# Construir la imagen y exportar a tar OCI
BUILD_OCI_IMAGE=false
if $BUILD_OCI_IMAGE; then
docker buildx build --platform linux/arm64,linux/amd64 \
    --output "type=oci,dest=tars/$DOCKERFILE_NAME.oci.tar" \
    -t "$DOCKERFILE_NAME" \
    "$DOCKERFILE_PATH"
fi
# Fin Construir la imagen y exportar a tar OCI

# Construir la imagen y exportar a tar AMD64
BUILD_AMD64_IMAGE=false
if $BUILD_AMD64_IMAGE; then
docker buildx build --platform linux/amd64 \
    --output "type=docker,dest=tars/$DOCKERFILE_NAME.amd64.tar" \
    -t "$DOCKERFILE_NAME" \
    "$DOCKERFILE_PATH"
fi
# Fin Construir la imagen y exportar a tar AMD64

# Construir la imagen y exportar a tar ARM64
BUILD_ARM64_IMAGE=true
if $BUILD_ARM64_IMAGE; then
docker buildx build --platform linux/arm64 \
    --output "type=docker,dest=tars/$DOCKERFILE_NAME.arm64.tar" \
    -t "$DOCKERFILE_NAME" \
    "$DOCKERFILE_PATH"
fi
# Fin Construir la imagen y exportar a tar ARM64

