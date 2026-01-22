#!/bin/bash

# Elegir un Dockerfile
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
# Fin Elegir un Dockerfile

# Arrancar proceso de construcción de imágenes Docker
bash scripts/docker-build.sh "$DOCKERFILE_PATH"
# Fin Arrancar proceso de construcción de imágenes Docker

# Elegir un perfil de AWS 
AWS_PROFILES=($(aws configure list-profiles))
echo "Elige un perfil de AWS:"
select AWS_PROFILE in "${AWS_PROFILES[@]}"; do
  if [[ -n "$AWS_PROFILE" ]]; then
    echo "Has elegido el perfil de AWS: $AWS_PROFILE"
    export AWS_PROFILE
    break
  else
    echo "Opción inválida, prueba otra vez."
  fi
done
# Fin Elegir un perfil de AWS 

# Elige una región de AWS
AWS_REGIONS=($(aws ec2 describe-regions --query "Regions[].RegionName" --output text))
echo "Elige una región de AWS:"
select AWS_REGION in "${AWS_REGIONS[@]}"; do
  if [[ -n "$AWS_REGION" ]]; then
    echo "Has elegido la región de AWS: $AWS_REGION"
    export AWS_REGION
    break
  else
    echo "Opción inválida, prueba otra vez."
  fi
done
# Fin Elige una región de AWS

# Test de credenciales
if aws sts get-caller-identity --profile "$AWS_PROFILE" | jq; then
    echo "Las credenciales de AWS son válidas."
else
    echo "Error: Las credenciales de AWS no son válidas."
    exit 1
fi
# Fin Test de credenciales