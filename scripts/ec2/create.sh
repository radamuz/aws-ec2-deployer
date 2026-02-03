CREATE_EC2=true
if $CREATE_EC2; then
  if $EC2_EXISTS; then
    # Si la EC2 existe obtener el INSTANCE_ID
    echo -e "${CYAN}Inicio Bloque Si la EC2 existe obtener el INSTANCE_ID${NC}"
    echo "✅ La EC2 '$APP_NAME' ya existe."
    INSTANCE_ID=$(
    aws ec2 describe-instances \
      --filters \
        Name=tag:Name,Values="$APP_NAME" \
        Name=instance-state-name,Values=running \
      --query 'sort_by(Reservations[].Instances[], &LaunchTime)[-1].InstanceId' \
      --output text)
    echo "✅ INSTANCE_ID: $INSTANCE_ID"

    DESCRIBE_INSTANCES=false
    if $DESCRIBE_INSTANCES; then
    EC2_DESCRIBE_INSTANCES_OUTPUT_JSON=$(aws ec2 describe-instances \
      --instance-ids "$INSTANCE_ID")
    fi

    # Obtener la dirección IP pública
    PUBLIC_IP=$(
      aws ec2 describe-instances \
      --instance-ids "$INSTANCE_ID" \
      --query 'Reservations[0].Instances[0].PublicIpAddress' \
      --output text)
    echo "✅ PUBLIC_IP: $PUBLIC_IP"
    echo -e "${GREEN}Fin Bloque Si la EC2 existe obtener el INSTANCE_ID${NC}"
    # Fin Si la EC2 existe obtener el INSTANCE_ID
  else
    # Ubuntus: ami-01f79b1e4a5c64257 (64-bit (x86)) / ami-0df5c15a5f998e2ab (64-bit (Arm))
    # t3a.medium (64-bit (x86)) / t4g.medium (64-bit (Arm))
    # Arrancar nueva instancia EC2
    EC2_RUN_INSTANCES_OUTPUT_JSON=$(aws ec2 run-instances \
      --image-id "${AMI_ID}" \
      --instance-type "$INSTANCE_TYPE" \
      --key-name "$PEM_KEY_NAME" \
      --security-group-ids "$SECURITY_GROUP_ID" \
      --subnet-id "$SUBNET_ID" \
      --iam-instance-profile Name=$INSTANCE_PROFILE_NAME \
      --user-data file://"$USER_DATA_PATH" \
      --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$APP_NAME},{Key=Name2,Value=$APP_NAME}]" | jq)
    # Fin Arrancar nueva instancia EC2

    # Obtener el Instance ID
    INSTANCE_ID=$(
      echo "$EC2_RUN_INSTANCES_OUTPUT_JSON" \
      | jq -r '.Instances[0].InstanceId')
    echo "✅ INSTANCE_ID: $INSTANCE_ID"
    # Fin Obtener el Instance ID

    # Obtener la dirección IP pública
    PUBLIC_IP=$(
      aws ec2 describe-instances \
      --instance-ids "$INSTANCE_ID" \
      --query 'Reservations[0].Instances[0].PublicIpAddress' \
      --output text)
    echo "✅ PUBLIC_IP: $PUBLIC_IP"
    # Fin Obtener la dirección IP pública
  fi
fi