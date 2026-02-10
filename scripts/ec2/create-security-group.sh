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
  aws ec2 authorize-security-group-ingress \
    --group-id "$SECURITY_GROUP_ID" \
    --protocol tcp \
    --port 5432 \
    --cidr 0.0.0.0/0
fi
echo -e "${GREEN}Fin Bloque Agregar reglas al security group${NC}"
# Fin agregar reglas al security group