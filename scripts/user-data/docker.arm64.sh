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
rm -rf awscliv2.zip ./aws
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

# Start Add Docker's official GPG key:
echo -e "${CYAN}Add Docker's official GPG key:${NC}"
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo -e "${GREEN}Finished adding Docker's official GPG key.${NC}"
# End Add Docker's official GPG key

# Start Add the repository to Apt sources:
echo -e "${CYAN}Start Add the repository to Apt sources:${NC}"
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF
echo -e "${GREEN}End Add the repository to Apt sources.${NC}"
sudo apt update -y
# End Add the repository to Apt sources

# Start Docker installation
echo -e "${CYAN}Start Docker installation${NC}"
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
echo -e "${GREEN}End Docker installation${NC}"
# End Docker installation

# Start Add ubuntu user to the docker group
echo -e "${CYAN}Start Add ubuntu user to the docker group${NC}"
sudo usermod -aG docker ubuntu
echo -e "${GREEN}End Add ubuntu user to the docker group${NC}"
# End Add ubuntu user to the docker group