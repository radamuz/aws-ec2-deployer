for i in {1..12}; do
  if ssh -o ConnectTimeout=5 -i "$PEM_KEY_REALPATH" ubuntu@"$PUBLIC_IP" "docker --version"; then
    echo -e "${GREEN}Docker está instalado en el intento $i${NC}"
    break
  else
    echo -e "${YELLOW}Intento $i: Docker no está instalado${NC}"
    sleep 10
  fi
done