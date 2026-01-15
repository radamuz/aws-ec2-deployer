#!/bin/bash

echo "Lista de Dockerfiles:"
ls dockerfiles

read -p "Elige un Dockerfile: " DOCKERFILE

DOCKERFILE_PATH="dockerfiles/$DOCKERFILE"

bash scripts/docker-build.sh $DOCKERFILE_PATH