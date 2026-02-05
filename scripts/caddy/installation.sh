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

# Inicio Bloque Instalación de Caddy
echo -e "${CYAN}Inicio Bloque Instalación de Caddy${NC}"
sudo apt install caddy -y
echo -e "${GREEN}Fin Bloque Instalación de Caddy${NC}"
# Fin Bloque Instalación de Caddy