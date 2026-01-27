#!/usr/bin/env bash
set -euo pipefail

# Requisitos:
#   - aws cli v2 configurado (credenciales + región por defecto o AWS_REGION)
#   - jq
#
# Uso:
#   ./latest-verified-amis.sh [region]
# Ej:
#   ./latest-verified-amis.sh eu-west-1

export AWS_PROFILE="${1:-default}"

REGION="${2:-${AWS_REGION:-}}"
if [[ -z "${REGION}" ]]; then
  REGION="$(aws configure get region 2>/dev/null || true)"
fi
if [[ -z "${REGION}" ]]; then
  echo "❌ No hay región. Pásala como argumento o define AWS_REGION o configura 'aws configure set region ...'"
  exit 1
fi

need() { command -v "$1" >/dev/null 2>&1 || { echo "❌ Falta '$1' en PATH"; exit 1; }; }
need aws
need jq

ssm_get() {
  local name="$1"
  aws ssm get-parameter \
    --region "$REGION" \
    --name "$name" \
    --query 'Parameter.Value' \
    --output text 2>/dev/null
}

describe_ami() {
  local ami="$1"
  aws ec2 describe-images \
    --region "$REGION" \
    --image-ids "$ami" \
    --query 'Images[0].{ImageId:ImageId,Name:Name,CreationDate:CreationDate,OwnerId:OwnerId,PlatformDetails:PlatformDetails}' \
    --output json
}

# Devuelve el último AMI (CreationDate) que cumpla owner + name-pattern (+ filtros típicos HVM/EBS/x86_64)
latest_by_name_pattern() {
  local owner="$1"
  local pattern="$2"

  aws ec2 describe-images \
    --region "$REGION" \
    --owners "$owner" \
    --filters \
      "Name=state,Values=available" \
      "Name=virtualization-type,Values=hvm" \
      "Name=root-device-type,Values=ebs" \
      "Name=architecture,Values=x86_64" \
      "Name=name,Values=${pattern}" \
    --query 'sort_by(Images, &CreationDate)[-1].{ImageId:ImageId,Name:Name,CreationDate:CreationDate,OwnerId:OwnerId,PlatformDetails:PlatformDetails}' \
    --output json
}

# --------- 1) Amazon Linux (AL2023) (SSM) ----------
AL2023_SSM="/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
AL2023_AMI="$(ssm_get "$AL2023_SSM" || true)"

# --------- 2) Ubuntu 24.04 (Canonical SSM) ----------
UBUNTU2404_SSM="/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
UBUNTU2404_AMI="$(ssm_get "$UBUNTU2404_SSM" || true)"

# --------- 3) macOS (SSM) - elige la versión más nueva disponible ----------
# Listamos parámetros y priorizamos versiones nuevas. Si AWS añade otra (p.ej. sequoia),
# la incluimos arriba para que se autoseleccione.
MACOS_PREF_ORDER=("sequoia" "sonoma" "ventura" "monterey")
MACOS_PARAMS_JSON="$(aws ssm get-parameters-by-path --region "$REGION" --path /aws/service/ec2-macos --recursive --output json 2>/dev/null || echo '{}')"

pick_macos_param() {
  local arch_path="x86_64_mac"
  # Candidatos que terminan en /latest/image_id y contienen /x86_64_mac/
  local candidates
  candidates="$(echo "$MACOS_PARAMS_JSON" | jq -r '.Parameters[]?.Name | select(test("/'"$arch_path"'/latest/image_id$"))' | sort -u)"

  if [[ -z "$candidates" ]]; then
    echo ""
    return 0
  fi

  # Intentamos por orden preferido
  for v in "${MACOS_PREF_ORDER[@]}"; do
    local hit
    hit="$(echo "$candidates" | awk -v ver="/$v/" '$0 ~ ver {print; exit}')"
    if [[ -n "$hit" ]]; then
      echo "$hit"
      return 0
    fi
  done

  # Fallback: el primero (si no coincide con nuestros nombres conocidos)
  echo "$candidates" | head -n1
}

MACOS_SSM_PARAM="$(pick_macos_param)"
MACOS_AMI=""
if [[ -n "$MACOS_SSM_PARAM" ]]; then
  MACOS_AMI="$(ssm_get "$MACOS_SSM_PARAM" || true)"
fi

# --------- 4) Windows Server (SSM) - prioriza 2025, luego 2022 ----------
WIN_PARAMS_JSON="$(aws ssm get-parameters-by-path --region "$REGION" --path /aws/service/ami-windows-latest --recursive --output json 2>/dev/null || echo '{}')"

pick_windows_param() {
  local candidates
  candidates="$(echo "$WIN_PARAMS_JSON" | jq -r '.Parameters[]?.Name' | sort -u)"

  # Preferencias (puedes ajustar si quieres Core, SQL, etc.)
  local prefs=(
    "/aws/service/ami-windows-latest/Windows_Server-2025-English-Full-Base"
    "/aws/service/ami-windows-latest/BIOS-Windows_Server-2025-English-Full-Base"
    "/aws/service/ami-windows-latest/Windows_Server-2022-English-Full-Base"
  )

  for p in "${prefs[@]}"; do
    if echo "$candidates" | grep -qx "$p"; then
      echo "$p"
      return 0
    fi
  done

  # Fallback razonable: cualquier "Windows_Server-2025...Full-Base" o "2022"
  local hit
  hit="$(echo "$candidates" | grep -E '^/aws/service/ami-windows-latest/(BIOS-)?Windows_Server-2025-.*-Full-Base$' | head -n1 || true)"
  if [[ -n "$hit" ]]; then echo "$hit"; return 0; fi

  hit="$(echo "$candidates" | grep -E '^/aws/service/ami-windows-latest/Windows_Server-2022-.*-Full-Base$' | head -n1 || true)"
  if [[ -n "$hit" ]]; then echo "$hit"; return 0; fi

  echo ""
}

WIN_SSM_PARAM="$(pick_windows_param)"
WIN_AMI=""
if [[ -n "$WIN_SSM_PARAM" ]]; then
  WIN_AMI="$(ssm_get "$WIN_SSM_PARAM" || true)"
fi

# --------- 5) RHEL (Red Hat) - owner oficial ----------
# Red Hat (public partition): 309956199498
# (En GovCloud es otro, pero aquí asumimos partición estándar)
RHEL_OWNER="309956199498"
# Preferimos RHEL 9 (actual), y si no aparece, caemos a RHEL 8
RHEL_JSON="$(latest_by_name_pattern "$RHEL_OWNER" "RHEL-9.*HVM-*x86_64*" || echo '{}')"
if [[ "$(echo "$RHEL_JSON" | jq -r '.ImageId // empty')" == "" ]]; then
  RHEL_JSON="$(latest_by_name_pattern "$RHEL_OWNER" "RHEL-8.*HVM-*x86_64*" || echo '{}')"
fi

# --------- 6) SUSE SLES - owner conocido ----------
SUSE_OWNER="013907871322"
# Patrón típico de SLES 15 (SPx), puede variar por región/edición
SUSE_JSON="$(latest_by_name_pattern "$SUSE_OWNER" "suse-sles-15-sp*-v*-hvm-ssd-x86_64" || echo '{}')"

# --------- 7) Debian - owner oficial ----------
DEBIAN_OWNER="136693071363"
# Traemos un set y elegimos: mayor versión (debian-<N>-...) y luego más reciente
DEBIAN_LIST_JSON="$(aws ec2 describe-images \
  --region "$REGION" \
  --owners "$DEBIAN_OWNER" \
  --filters \
    "Name=state,Values=available" \
    "Name=virtualization-type,Values=hvm" \
    "Name=root-device-type,Values=ebs" \
    "Name=architecture,Values=x86_64" \
    "Name=name,Values=debian-*-amd64-*" \
  --query 'Images[*].{ImageId:ImageId,Name:Name,CreationDate:CreationDate,OwnerId:OwnerId,PlatformDetails:PlatformDetails}' \
  --output json 2>/dev/null || echo '[]')"

DEBIAN_JSON="$(
  echo "$DEBIAN_LIST_JSON" | jq -c '
    map(. + {Major:(.Name|capture("^debian-(?<m>[0-9]+)")?.m // "0" | tonumber)}) |
    (max_by(.Major).Major) as $best |
    map(select(.Major == $best)) |
    max_by(.CreationDate) |
    del(.Major)
  ' 2>/dev/null || echo '{}'
)"

# --------- Formato salida ----------
print_row() {
  local os="$1"
  local json="$2"
  local ami name date owner plat
  ami="$(echo "$json" | jq -r '.ImageId // "-"')"
  name="$(echo "$json" | jq -r '.Name // "-"')"
  date="$(echo "$json" | jq -r '.CreationDate // "-"')"
  owner="$(echo "$json" | jq -r '.OwnerId // "-"')"
  plat="$(echo "$json" | jq -r '.PlatformDetails // "-"')"
  printf "%-14s  %-14s  %-10s  %-12s  %s\n" "$os" "$ami" "$date" "$owner" "$name"
}

echo "✅ Región: $REGION"
echo
printf "%-14s  %-14s  %-10s  %-12s  %s\n" "OS" "AMI" "Creada" "OwnerId" "Name"
printf "%-14s  %-14s  %-10s  %-12s  %s\n" "--------------" "--------------" "----------" "------------" "------------------------------"

# Amazon Linux
if [[ -n "${AL2023_AMI}" ]]; then
  print_row "AmazonLinux" "$(describe_ami "$AL2023_AMI")"
else
  print_row "AmazonLinux" "{}"
fi

# macOS
if [[ -n "${MACOS_AMI}" ]]; then
  print_row "macOS" "$(describe_ami "$MACOS_AMI")"
else
  print_row "macOS" "{}"
fi

# RHEL
print_row "RedHat" "$RHEL_JSON"

# SUSE
print_row "SUSE" "$SUSE_JSON"

# Ubuntu 24.04
if [[ -n "${UBUNTU2404_AMI}" ]]; then
  print_row "Ubuntu24.04" "$(describe_ami "$UBUNTU2404_AMI")"
else
  print_row "Ubuntu24.04" "{}"
fi

# Debian
print_row "Debian" "$DEBIAN_JSON"

# Windows
if [[ -n "${WIN_AMI}" ]]; then
  print_row "Windows" "$(describe_ami "$WIN_AMI")"
else
  print_row "Windows" "{}"
fi

echo
echo "ℹ️  Windows param elegido: ${WIN_SSM_PARAM:-"-"}"
echo "ℹ️  macOS param elegido:   ${MACOS_SSM_PARAM:-"-"}"
echo "ℹ️  AmazonLinux param:     $AL2023_SSM"
echo "ℹ️  Ubuntu 24.04 param:    $UBUNTU2404_SSM"
