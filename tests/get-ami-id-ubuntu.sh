#!/usr/bin/env bash
set -euo pipefail

ARCH="${1:-}"

if [[ -z "$ARCH" ]]; then
  echo "❌ Uso: $0 <amd64|arm64>"
  exit 1
fi

case "$ARCH" in
  amd64|arm64)
    ;;
  *)
    echo "❌ Arquitectura inválida: $ARCH (usa amd64 o arm64)"
    exit 1
    ;;
esac

SSM_PARAM="/aws/service/canonical/ubuntu/server/24.04/stable/current/${ARCH}/hvm/ebs-gp3/ami-id"

AMI_ID=$(aws ssm get-parameter \
  --name "$SSM_PARAM" \
  --query 'Parameter.Value' \
  --output text)

echo "$AMI_ID"
