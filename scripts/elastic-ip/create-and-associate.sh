#!/usr/bin/env bash

echo "📌 Creando Elastic IP en $AWS_REGION..."

ALLOCATION_ID=$(aws ec2 allocate-address \
  --domain vpc \
  --region "$AWS_REGION" \
  --tag-specifications "ResourceType=elastic-ip,Tags=[{Key=Name,Value=$APP_NAME},{Key=Name2,Value=$APP_NAME}]" \
  --query 'AllocationId' \
  --output text)

echo "✅ Elastic IP creada. AllocationId: $ALLOCATION_ID"

# Asegurate que la instancia $INSTANCE_ID esté en un estado "running" y si no lo está haz try hasta que esté listo para asociar la IP
INSTANCE_STATE=$(aws ec2 describe-instances \
  --instance-ids "$INSTANCE_ID" \
  --region "$AWS_REGION" \
  --query 'Reservations[0].Instances[0].State.Name' \
  --output text)

while [ "$INSTANCE_STATE" != "running" ]; do
  echo "🔄 La instancia $INSTANCE_ID no está en estado 'running', esperando..."
  sleep 5
  INSTANCE_STATE=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --region "$AWS_REGION" \
    --query 'Reservations[0].Instances[0].State.Name' \
    --output text)
done

echo "🔗 Asociando Elastic IP a la instancia $INSTANCE_ID..."

ASSOCIATION_ID=$(aws ec2 associate-address \
  --instance-id "$INSTANCE_ID" \
  --allocation-id "$ALLOCATION_ID" \
  --region "$AWS_REGION" \
  --query 'AssociationId' \
  --output text)

echo "✅ Elastic IP asociada. AssociationId: $ASSOCIATION_ID"

PUBLIC_IP=$(aws ec2 describe-addresses \
  --allocation-ids "$ALLOCATION_ID" \
  --region "$AWS_REGION" \
  --query 'Addresses[0].PublicIp' \
  --output text)

echo "🌍 IP pública asignada: $PUBLIC_IP"
