# Crear security group
echo -e "${CYAN}Inicio Bloque Crear security group${NC}"
CREATE_SECURITY_GROUP=true
SECURITY_GROUP_NAME="$APP_NAME-sg"
if $CREATE_SECURITY_GROUP; then
  SECURITY_GROUP_ID=$(
    aws ec2 describe-security-groups \
      --filters "Name=group-name,Values=$SECURITY_GROUP_NAME" \
      --query 'SecurityGroups[0].GroupId' \
      --output text 2>/dev/null || true
  )

  if [[ -n "$SECURITY_GROUP_ID" && "$SECURITY_GROUP_ID" != "None" ]]; then
    echo "✅ El security group $SECURITY_GROUP_NAME ya existe ($SECURITY_GROUP_ID)"
  else
    echo "ℹ️  Creando security group $SECURITY_GROUP_NAME..."
    aws ec2 create-security-group \
      --group-name "$SECURITY_GROUP_NAME" \
      --description "Security group for $APP_NAME" >/dev/null
  fi
fi
echo -e "${GREEN}Fin Bloque Crear security group${NC}"
# Fin crear security group

# Obtener el security group ID
echo -e "${CYAN}Inicio Bloque Obtener el security group ID${NC}"
if $CREATE_SECURITY_GROUP; then
  SECURITY_GROUP_ID=$(
    aws ec2 describe-security-groups \
    --filters "Name=group-name,Values=$SECURITY_GROUP_NAME" \
    --query 'SecurityGroups[0].GroupId' \
    --output text)
fi
echo -e "${GREEN}Fin Bloque Obtener el security group ID${NC}"
# Fin Obtener el security group ID

# Agregar reglas al security group
echo -e "${CYAN}Inicio Bloque Agregar reglas al security group${NC}"
if $CREATE_SECURITY_GROUP; then
  for PORT in 22 80 443 5432; do
    if aws ec2 authorize-security-group-ingress \
      --group-id "$SECURITY_GROUP_ID" \
      --protocol tcp \
      --port "$PORT" \
      --cidr 0.0.0.0/0 >/dev/null 2>&1; then
      echo "✅ Regla añadida en puerto $PORT"
    else
      echo "ℹ️  La regla del puerto $PORT ya existe o no requiere cambios"
    fi
  done
fi
echo -e "${GREEN}Fin Bloque Agregar reglas al security group${NC}"
# Fin agregar reglas al security group
