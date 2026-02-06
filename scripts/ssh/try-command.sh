for i in {1..12}; do
  if ssh -o ConnectTimeout=5 -i "$PEM_KEY_REALPATH" ubuntu@"$PUBLIC_IP" "${SSH_TRY_COMMAND}"; then
    echo -e "${GREEN}El comando ${SSH_TRY_COMMAND} se ejecutó con éxito en el intento $i${NC}"
    break
  else
    echo -e "${YELLOW}Intento $i: El comando ${SSH_TRY_COMMAND} falló su ejecución${NC}"
    sleep 10
  fi
done