#!/bin/bash

DOCKERFILES=(dockerfiles/*)

echo "Elige un Dockerfile:"

select DOCKERFILE_PATH in "${DOCKERFILES[@]}"; do
  if [[ -n "$DOCKERFILE_PATH" ]]; then
    echo "Has elegido: $DOCKERFILE_PATH"
    break
  else
    echo "Opción inválida, prueba otra vez."
  fi
done


bash scripts/docker-build.sh "$DOCKERFILE_PATH"