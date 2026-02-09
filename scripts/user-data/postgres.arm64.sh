#!/usr/bin/env bash

# Inicio Aplicar colores de bash
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

# Inicio Que el script se detenga automáticamente cuando un comando falla
echo -e "${CYAN}Inicio Que el script se detenga automáticamente cuando un comando falla${NC}"
echo -e "${GREEN}Fin Que el script se detenga automáticamente cuando un comando falla${NC}"
set -e
# Fin Que el script se detenga automáticamente cuando un comando falla

# Inicio Obtenemos el token de metadata para poder hacer consultas al metadata
echo -e "${CYAN}Inicio Obtenemos el token de metadata para poder hacer consultas al metadata${NC}"
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
echo -e "${GREEN}Fin Obtenemos el token de metadata para poder hacer consultas al metadata${NC}"
# Fin Obtenemos el token de metadata para poder hacer consultas al metadata

# Inicio Obtenemos el ID de la instancia y la región
echo -e "${CYAN}Inicio Obtenemos el ID de la instancia y la región${NC}"
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id \
  -H "X-aws-ec2-metadata-token: $TOKEN")
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region \
  -H "X-aws-ec2-metadata-token: $TOKEN")
echo -e "${GREEN}Fin Obtenemos el ID de la instancia y la región${NC}"
# Fin Obtenemos el ID de la instancia y la región

# Inicio Instalamos dependencias
echo -e "${CYAN}Inicio Instalamos dependencias${NC}"
apt update -y
apt install curl unzip ca-certificates -y
echo -e "${GREEN}Fin Instalamos dependencias${NC}"
# Fin Instalamos dependencias

# Inicio Instalamos AWS CLI
echo -e "${CYAN}Inicio Instalamos AWS CLI${NC}"
cd /tmp
curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -f awscliv2.zip
cd -
echo -e "${GREEN}Fin Instalamos AWS CLI${NC}"
# Fin Instalamos AWS CLI

# Inicio Seteamos el hostname de la instancia segun el tag Name
echo -e "${CYAN}Inicio Seteamos el hostname de la instancia segun el tag Name${NC}"
APP_NAME=$(aws ec2 describe-tags \
  --region "$REGION" \
  --filters "Name=resource-id,Values=$INSTANCE_ID" "Name=key,Values=Name" \
  --query 'Tags[0].Value' \
  --output text)
hostnamectl set-hostname "$APP_NAME"
echo -e "${GREEN}Fin Seteamos el hostname de la instancia segun el tag Name${NC}"
# Fin Seteamos el hostname de la instancia segun el tag Name

# Inicio Instalamos postgresql
echo -e "${CYAN}Inicio Instalamos postgresql${NC}"
apt update -y
apt install postgresql postgresql-contrib -y
echo -e "${GREEN}Fin Instalamos postgresql${NC}"
# Fin Instalamos postgresql

# Inicio Habilitamos el servicio de postgresql para que inicie al arrancar la instancia
echo -e "${CYAN}Inicio Habilitamos el servicio de postgresql para que inicie al arrancar la instancia${NC}"
sudo systemctl enable postgresql
echo -e "${GREEN}Fin Habilitamos el servicio de postgresql para que inicie al arrancar la instancia${NC}"
# Fin Habilitamos el servicio de postgresql para que inicie al arrancar la instancia

