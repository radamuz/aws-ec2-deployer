for i in {1..12}; do
  if ssh -o ConnectTimeout=5 -i "$PEM_KEY_REALPATH" ubuntu@"$PUBLIC_IP" "exit"; then
    echo -e "${GREEN}Conexión SSH establecida con éxito en el intento $i${NC}"
    break
  else
    echo -e "${YELLOW}Intento $i: No se pudo establecer la conexión SSH${NC}"
    sleep 5
  fi
done