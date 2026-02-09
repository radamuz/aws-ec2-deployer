# Inicio Bloque Haz un for i in {1..12} para comprobar con ssh si hay conexion ya scripts/ssh/try-basic-connection.sh
echo -e "${CYAN}Inicio Bloque Comprobar si hay conexión SSH scripts/ssh/try-basic-connection.sh${NC}"
source scripts/ssh/try-basic-connection.sh
echo -e "${GREEN}Fin Bloque Comprobar si hay conexión SSH scripts/ssh/try-basic-connection.sh${NC}"
# Fin Bloque Comprobar si hay conexión SSH scripts/ssh/try-basic-connection.sh

# Inicio Bloque az un for i in {1..12} para comprobar con ssh si ya se ha instalado el aplicativo
echo -e "${CYAN}Inicio Bloque Comprobar con ssh si ya se ha instalado el aplicativo${NC}"
source scripts/ssh/try-command.sh
echo -e "${GREEN}Fin Bloque Comprobar con ssh si ya se ha instalado el aplicativo${NC}"
# Fin Bloque Comprobar con ssh si ya se ha instalado el aplicativo

# Inicio Enviar imagen de contenedor a la máquina EC2 scripts/ssh/docker-actions.sh
if [[ "$DOCKERFILE_PATH" != "dockerfiles/none" ]]; then
  echo -e "${CYAN}Inicio Bloque Enviar imagen de contenedor a la máquina EC2 scripts/ssh/docker-actions.sh${NC}"
  source scripts/ssh/docker-actions.sh
  echo -e "${GREEN}Fin Bloque Enviar imagen de contenedor a la máquina EC2 scripts/ssh/docker-actions.sh${NC}"
fi
# Fin Enviar imagen de contenedor a la máquina EC2 scripts/ssh/docker-actions.sh