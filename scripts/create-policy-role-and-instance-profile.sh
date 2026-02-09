#!/usr/bin/env bash
set -euo pipefail

export AWS_PAGER=""
export AWS_PROFILE="$1"
export AWS_REGION="$2"
export APP_NAME="$3"

# ===== Variables =====
ROLE_NAME="$APP_NAME-role"
POLICY_NAME="$APP_NAME-policy"
INSTANCE_PROFILE_NAME="$APP_NAME-instance-profile"

POLICY_JSON_FILE="config/iam/ec2-describe-tags-policy.json"
TRUST_POLICY_JSON_FILE="config/iam/ec2-assume-role-trust-policy.json"


ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
POLICY_ARN="arn:aws:iam::$ACCOUNT_ID:policy/$POLICY_NAME"

echo "▶ Creando policy IAM (si no existe)..."
if ! aws iam get-policy --policy-arn "$POLICY_ARN" >/dev/null 2>&1; then
  aws iam create-policy \
    --policy-name "$POLICY_NAME" \
    --policy-document "file://$POLICY_JSON_FILE"
else
  echo "✔ Policy ya existe"
fi

echo "▶ Creando rol IAM (si no existe)..."
if ! aws iam get-role --role-name "$ROLE_NAME" >/dev/null 2>&1; then
  aws iam create-role \
    --role-name "$ROLE_NAME" \
    --assume-role-policy-document "file://$TRUST_POLICY_JSON_FILE"
else
  echo "✔ Rol ya existe"
fi

echo "▶ Verificando y asociando policies gestionadas por AWS al rol..."
AWS_MANAGED_POLICIES=(
  "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  "arn:aws:iam::aws:policy/AmazonSSMPatchAssociation"
)

ATTACHED_POLICY_ARNS="$(aws iam list-attached-role-policies \
  --role-name "$ROLE_NAME" \
  --query 'AttachedPolicies[].PolicyArn' \
  --output text)"

for POLICY_ARN_TO_ATTACH in "${AWS_MANAGED_POLICIES[@]}"; do
  if echo "$ATTACHED_POLICY_ARNS" | tr '\t' '\n' | grep -Fxq "$POLICY_ARN_TO_ATTACH"; then
    echo "✔ Ya asociada: $POLICY_ARN_TO_ATTACH"
  else
    echo "▶ Asociando: $POLICY_ARN_TO_ATTACH"
    aws iam attach-role-policy \
      --role-name "$ROLE_NAME" \
      --policy-arn "$POLICY_ARN_TO_ATTACH"
  fi
done

echo "▶ Asociando policy al rol..."
aws iam attach-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-arn "$POLICY_ARN" || true

echo "▶ Creando instance profile (si no existe)..."
if ! aws iam get-instance-profile --instance-profile-name "$INSTANCE_PROFILE_NAME" >/dev/null 2>&1; then
  aws iam create-instance-profile \
    --instance-profile-name "$INSTANCE_PROFILE_NAME"
else
  echo "✔ Instance profile ya existe"
fi

echo "▶ Añadiendo rol al instance profile..."
aws iam add-role-to-instance-profile \
  --instance-profile-name "$INSTANCE_PROFILE_NAME" \
  --role-name "$ROLE_NAME" || true

echo "⏳ Esperando a que el instance profile esté disponible..."

for i in {1..12}; do
  sleep 1
  if aws iam get-instance-profile \
       --instance-profile-name "$INSTANCE_PROFILE_NAME" \
       --query 'InstanceProfile.Roles[0].RoleName' \
       --output text 2>/dev/null | grep -q .; then
    echo "✅ Instance profile listo"
    break
  fi

  echo "⏱️  Aún no disponible… reintentando ($i)"
  sleep 1
done

echo "⏳ Esperando 10 segundos adicionales para asegurar la propagación de cambios..."
sleep 10

echo
echo "✅ TODO LISTO"
echo "Instance Profile: $INSTANCE_PROFILE_NAME"
