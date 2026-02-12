# Inicio Bloque Elegir el comando a probar con ssh
echo -e "${CYAN}Inicio Bloque Elegir el comando a probar con ssh${NC}"
echo "Elige el comando a probar con ssh:"
mapfile -t SSH_COMMANDS < config/ssh-try-commands.txt
select SSH_TRY_COMMAND in "${SSH_COMMANDS[@]}"; do
  if [[ -n "$SSH_TRY_COMMAND" ]]; then
    echo "Has elegido el comando a probar con ssh: $SSH_TRY_COMMAND"
    export SSH_TRY_COMMAND
    break
  else
    echo "Opción inválida, prueba otra vez."
  fi
done
echo -e "${GREEN}Fin Bloque Elegir el comando a probar con ssh${NC}"
# Fin Bloque Elegir el comando a probar con ssh


for i in {1..36}; do
  if ssh -o ConnectTimeout=5 -i "$PEM_KEY_REALPATH" ubuntu@"$PUBLIC_IP" "${SSH_TRY_COMMAND}"; then
    echo -e "${GREEN}El comando ${SSH_TRY_COMMAND} se ejecutó con éxito en el intento $i${NC}"
    break
  else
    echo -e "${YELLOW}Intento $i: El comando ${SSH_TRY_COMMAND} falló su ejecución${NC}"
    sleep 10
  fi
done