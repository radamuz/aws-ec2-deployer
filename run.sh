#!/bin/bash

# Aplicar colores de bash
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
ORANGE='\033[0;33m'
PURPLE='\033[0;35m'
BROWN='\033[0;33m'
CYAN="\e[36m"
NC='\033[0m' # No Color
# Fin Aplicar colores de bash

# Que aws cli no use less
echo -e "${CYAN}Inicio Bloque Que aws cli no use less${NC}"
export AWS_PAGER=""
echo -e "${GREEN}Fin Bloque Que aws cli no use less${NC}"
# Fin Que aws cli no use less


# Elegir un Dockerfile
echo -e "${CYAN}Inicio Bloque Elegir un Dockerfile${NC}"
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
echo -e "${GREEN}Fin Bloque Elegir un Dockerfile${NC}"
# Fin Elegir un Dockerfile

# Arrancar proceso de construcción de imágenes Docker
echo -e "${CYAN}Inicio Bloque Arrancar proceso de construcción de imágenes Docker${NC}"
RUN_DOCKER_BUILD=true
if $RUN_DOCKER_BUILD; then
  source scripts/docker-build.sh "$DOCKERFILE_PATH"
fi
echo -e "${GREEN}Fin Bloque Arrancar proceso de construcción de imágenes Docker${NC}"
# Fin Arrancar proceso de construcción de imágenes Docker

# Elegir un perfil de AWS 
echo -e "${CYAN}Inicio Bloque Elegir un perfil de AWS${NC}"
AWS_PROFILES=($(aws configure list-profiles | sort))
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
echo -e "${GREEN}Fin Bloque Elegir un perfil de AWS${NC}"
# Fin Elegir un perfil de AWS

# Elige una región de AWS con ./scripts/select-aws-region.sh
echo -e "${CYAN}Inicio Bloque Elegir una región de AWS${NC}"
source ./scripts/select-aws-region.sh
echo -e "AWS_REGION: $AWS_REGION"
echo -e "${GREEN}Fin Bloque Elegir una región de AWS${NC}"
# Fin Elige una región de AWS con ./scripts/select-aws-region.sh

# Test de credenciales
echo -e "${CYAN}Inicio Bloque Test de credenciales${NC}"
AWS_STS_GET_CALLER_IDENTITY=$(aws sts get-caller-identity --profile "$AWS_PROFILE")
AWS_STS_GET_CALLER_IDENTITY_STATUS=$?
echo "$AWS_STS_GET_CALLER_IDENTITY" | jq
if [ $AWS_STS_GET_CALLER_IDENTITY_STATUS -eq 0 ]; then
    echo "Las credenciales de AWS son válidas."
else
    echo "Error: Las credenciales de AWS no son válidas."
    exit 1
fi
echo -e "${GREEN}Fin Bloque Test de credenciales${NC}"
# Fin Test de credenciales

# Introduce el nombre del aplicativo a desplegar
echo -e "${CYAN}Inicio Bloque Introduce el nombre del aplicativo a desplegar${NC}"
read -p "Nombre del aplicativo: " APP_NAME
APP_NAME=${APP_NAME:-aws-ec2-docker-deployer}
APP_NAME=${APP_NAME}-aedd
echo -e "${GREEN}Fin Bloque Introduce el nombre del aplicativo a desplegar${NC}"
# Fin Introduce el nombre del aplicativo a desplegar

# Asegurarse de que existe la carpeta keypairs
echo -e "${CYAN}Inicio Bloque Asegurarse de que existe la carpeta keypairs${NC}"
mkdir -p keypairs
echo -e "${GREEN}Fin Bloque Asegurarse de que existe la carpeta keypairs${NC}"
# Fin Asegurarse de que existe la carpeta keypairs

# Crear key pair
echo -e "${CYAN}Inicio Bloque Crear key pair${NC}"
source scripts/ec2/create-key-pair.sh
echo -e "${GREEN}Fin Bloque Crear key pair${NC}"
# Fin crear key pair

# Hacer cat $PEM_KEY_PATH y subirlo al secret manager si no existe
echo -e "${CYAN}Inicio Bloque Hacer cat \$PEM_KEY_PATH y subirlo al secret manager si no existe${NC}"
if ! aws secretsmanager describe-secret --secret-id "$PEM_KEY_PATH" >/dev/null 2>&1; then
  echo "❌ El secreto NO existe, creando..."
  aws secretsmanager create-secret --name "$PEM_KEY_PATH" --secret-string file://"$PEM_KEY_PATH" | jq
else
  echo "✅ El secreto ya existe"
fi
echo -e "${GREEN}Fin Bloque Hacer cat \$PEM_KEY_PATH y subirlo al secret manager si no existe${NC}"
# Fin Hacer cat $PEM_KEY_PATH y subirlo al secret manager si no existe

# Crear security group
echo -e "${CYAN}Inicio Bloque Crear security group${NC}"
CREATE_SECURITY_GROUP=true
if $CREATE_SECURITY_GROUP; then
aws ec2 create-security-group \
  --group-name "$APP_NAME-sg" \
  --description "Security group for $APP_NAME"
fi
echo -e "${GREEN}Fin Bloque Crear security group${NC}"
# Fin crear security group

# Obtener el security group ID
echo -e "${CYAN}Inicio Bloque Obtener el security group ID${NC}"
if $CREATE_SECURITY_GROUP; then
SECURITY_GROUP_ID=$(
  aws ec2 describe-security-groups \
  --filters Name=group-name,Values="$APP_NAME-sg" \
  --query 'SecurityGroups[0].GroupId' \
  --output text)
fi
echo -e "${GREEN}Fin Bloque Obtener el security group ID${NC}"
# Fin Obtener el security group ID

# Agregar reglas al security group
echo -e "${CYAN}Inicio Bloque Agregar reglas al security group${NC}"
if $CREATE_SECURITY_GROUP; then
aws ec2 authorize-security-group-ingress \
  --group-id "$SECURITY_GROUP_ID" \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress \
  --group-id "$SECURITY_GROUP_ID" \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress \
  --group-id "$SECURITY_GROUP_ID" \
  --protocol tcp \
  --port 443 \
  --cidr 0.0.0.0/0
fi
echo -e "${GREEN}Fin Bloque Agregar reglas al security group${NC}"
# Fin agregar reglas al security group

# Seleccionar VPC y Subnet
echo -e "${CYAN}Inicio Bloque Seleccionar VPC y Subnet${NC}"
source scripts/select-vpc-subnet.sh
echo -e "${GREEN}Fin Bloque Seleccionar VPC y Subnet${NC}"
# Fin Seleccionar VPC y Subnet

# Obtener el AMI ID
echo -e "${CYAN}Inicio Bloque Obtener el AMI ID${NC}"
source scripts/get-ami-id-ubuntu.sh
echo -e "${GREEN}Fin Bloque Obtener el AMI ID${NC}"
# Fin Obtener el AMI ID

# Comprobar si existe la EC2
echo -e "${CYAN}Inicio Bloque Comprobar si existe la EC2${NC}"
source scripts/ec2/check-name.sh
echo -e "${GREEN}Fin Bloque Comprobar si existe la EC2${NC}"
# Fin comprobar si existe la EC2

# Elegir el fichero user-data
echo -e "${CYAN}Inicio Bloque Elegir el fichero user-data${NC}"
echo "Elige el fichero user-data:"
select USER_DATA_FILE in $(ls scripts/user-data/); do
  if [[ -n "$USER_DATA_FILE" ]]; then
    echo "Has elegido el fichero user-data: $USER_DATA_FILE"

    export USER_DATA_PATH="$(realpath scripts/user-data/$USER_DATA_FILE)"
    break
  else
    echo "Opción inválida, prueba otra vez."
  fi
done
echo -e "${GREEN}Fin Bloque Elegir el fichero user-data${NC}"
# Fin Elegir el fichero user-data

# Elegir el instance type de AWS
echo -e "${CYAN}Inicio Bloque Elegir el instance type de AWS${NC}"
echo "Elige el instance type de AWS:"
select INSTANCE_TYPE in $(cat config/instance-types.txt); do
  if [[ -n "$INSTANCE_TYPE" ]]; then
    echo "Has elegido el instance type de AWS: $INSTANCE_TYPE"
    export INSTANCE_TYPE
    break
  else
    echo "Opción inválida, prueba otra vez."
  fi
done
echo -e "${GREEN}Fin Bloque Elegir el instance type de AWS${NC}"
# Fin Elegir el instance type de AWS

# Crear policy, role e instance profile
echo -e "${CYAN}Inicio Bloque Crear policy, role e instance profile${NC}"
bash scripts/create-policy-role-and-instance-profile.sh "$AWS_PROFILE" "$AWS_REGION" "$APP_NAME"
INSTANCE_PROFILE_NAME="$APP_NAME-instance-profile"
echo -e "${GREEN}Fin Bloque Crear policy, role e instance profile${NC}"
# Fin Crear policy, role e instance profile

# Si la EC2 no existe entonces creala scripts/ec2/create.sh
echo -e "${CYAN}Inicio Bloque Si la EC2 no existe entonces creala scripts/ec2/create.sh${NC}"
source scripts/ec2/create.sh
echo -e "${GREEN}Fin Bloque Si la EC2 no existe entonces creala scripts/ec2/create.sh${NC}"
# Fin Si la EC2 no existe entonces creala scripts/ec2/create.sh

# Con un select option di si o no si quieres asociarle una elastic ip scripts/elastic-ip/run.sh
echo -e "${CYAN}Inicio Bloque Con un select option di si o no si quieres asociarle una elastic ip scripts/elastic-ip/run.sh${NC}"
source scripts/elastic-ip/run.sh
echo -e "${GREEN}Fin Bloque Con un select option di si o no si quieres asociarle una elastic ip scripts/elastic-ip/run.sh${NC}"
# Fin Con un select option di si o no si quieres asociarle una elastic ip scripts/elastic-ip/run.sh

# Esperar a que la instancia esté arrancada
echo -e "${CYAN}Inicio Bloque Esperar a que la instancia esté arrancada${NC}"
aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"
echo -e "${GREEN}Fin Bloque Esperar a que la instancia esté arrancada${NC}"
# Fin Esperar a que la instancia esté arrancada

# Inicio Bloque Haz un for i in {1..12} para comprobar con ssh si hay conexion ya scripts/ssh/try.sh
echo -e "${CYAN}Inicio Bloque Comprobar si hay conexión SSH scripts/ssh/try.sh${NC}"
source scripts/ssh/try.sh
echo -e "${GREEN}Fin Bloque Comprobar si hay conexión SSH scripts/ssh/try.sh${NC}"
# Fin Bloque Comprobar si hay conexión SSH scripts/ssh/try.sh

# Inicio Bloque az un for i in {1..12} para comprobar con ssh si ya se ha instalado docker
echo -e "${CYAN}Inicio Bloque Comprobar si Docker está instalado${NC}"
source scripts/ssh/try-docker.sh
echo -e "${GREEN}Fin Bloque Comprobar si Docker está instalado${NC}"
# Fin Bloque Comprobar si Docker está instalado

# Inicio Enviar imagen de contenedor a la máquina EC2 scripts/ssh/actions.sh
echo -e "${CYAN}Inicio Bloque Enviar imagen de contenedor a la máquina EC2 scripts/ssh/actions.sh${NC}"
source scripts/ssh/actions.sh
echo -e "${GREEN}Fin Bloque Enviar imagen de contenedor a la máquina EC2 scripts/ssh/actions.sh${NC}"
# Fin Enviar imagen de contenedor a la máquina EC2 scripts/ssh/actions.sh

# Preguntar con un select si quieres realizar la instalación de caddy e introducir un nombre de dominio
echo -e "${CYAN}Inicio Bloque Preguntar con un select si quieres realizar la instalación de caddy e introducir un nombre de dominio${NC}"
source scripts/caddy/run.sh
echo -e "${GREEN}Fin Bloque Preguntar con un select si quieres realizar la instalación de caddy e introducir un nombre de dominio${NC}"
# Fin Preguntar con un select si quieres realizar la instalación de caddy e introducir un nombre de dominio

# Informar al usuario de que puede acceder a la máquina a través del siguiente comando scripts/display-info.sh
echo -e "${CYAN}Inicio Bloque Informar al usuario de que puede acceder a la máquina a través del siguiente comando scripts/display-info.sh${NC}"
source scripts/display-info.sh
echo -e "${GREEN}Fin Bloque Informar al usuario de que puede acceder a la máquina a través del siguiente comando scripts/display-info.sh${NC}"
# Fin Informar al usuario de que puede acceder a la máquina a través del siguiente comando scripts/display-info.sh

# Guardar registro de variables usadas scripts/write-log.sh
echo -e "${CYAN}Inicio Bloque Guardar registro de variables usadas scripts/write-log.sh${NC}"
source scripts/write-log.sh
echo -e "${GREEN}Fin Bloque Guardar registro de variables usadas scripts/write-log.sh${NC}"
# Fin Guardar registro de variables usadas scripts/write-log.sh
