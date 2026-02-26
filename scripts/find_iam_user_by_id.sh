#!/usr/bin/env bash
set -euo pipefail

TARGET_USER_ID="${1:-AIDA5T33TYR2QT75YPSLY}"

if ! command -v aws >/dev/null 2>&1; then
  echo "Error: aws CLI no está instalado o no está en el PATH." >&2
  exit 1
fi

mapfile -t PROFILES < <(aws configure list-profiles 2>/dev/null || true)

if [[ ${#PROFILES[@]} -eq 0 ]]; then
  echo "No se encontraron perfiles en AWS CLI (aws configure list-profiles)." >&2
  exit 1
fi

found_any=0

echo "Buscando IAM UserId: ${TARGET_USER_ID}"
echo "Perfiles detectados: ${#PROFILES[@]}"
echo

for profile in "${PROFILES[@]}"; do
  echo "==> Perfil: ${profile}"

  set +e
  result_json=$(aws iam list-users \
    --profile "${profile}" \
    --query "Users[?UserId=='${TARGET_USER_ID}'] | [0]" \
    --output json 2>&1)
  rc=$?
  set -e

  if [[ $rc -ne 0 ]]; then
    echo "  [ERROR] No se pudo consultar IAM en este perfil."
    echo "  Detalle: ${result_json}"
    echo
    continue
  fi

  if [[ "${result_json}" == "null" ]]; then
    echo "  [OK] No encontrado en este perfil."
    echo
    continue
  fi

  found_any=1
  username=$(aws iam list-users \
    --profile "${profile}" \
    --query "Users[?UserId=='${TARGET_USER_ID}'] | [0].UserName" \
    --output text)
  arn=$(aws iam list-users \
    --profile "${profile}" \
    --query "Users[?UserId=='${TARGET_USER_ID}'] | [0].Arn" \
    --output text)

  echo "  [FOUND] Usuario encontrado"
  echo "  UserName: ${username}"
  echo "  ARN: ${arn}"
  echo

done

if [[ $found_any -eq 0 ]]; then
  echo "Resultado final: el UserId ${TARGET_USER_ID} no apareció en ningún perfil consultado."
  exit 2
fi

echo "Resultado final: búsqueda completada con coincidencias."
