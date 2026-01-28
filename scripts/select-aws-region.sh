#!/usr/bin/env bash

echo -e "\n\n🏁 Arrancando el proceso de elección de región de AWS..."

# Mapa código → nombre legible
declare -A REGION_NAMES=(
  [ap-northeast-1]="Asia Pacific (Tokyo)"
  [ap-northeast-2]="Asia Pacific (Seoul)"
  [ap-northeast-3]="Asia Pacific (Osaka)"
  [ap-south-1]="Asia Pacific (Mumbai)"
  [ap-southeast-1]="Asia Pacific (Singapore)"
  [ap-southeast-2]="Asia Pacific (Sydney)"
  [ca-central-1]="Canada (Montreal)"
  [ca-west-1]="Canada (Calgary)"
  [eu-central-1]="Europe (Frankfurt)"
  [eu-north-1]="Europe (Stockholm)"
  [eu-south-1]="Europe (Milan)"
  [eu-south-2]="Europe (Spain)"
  [eu-west-1]="Europe (Ireland)"
  [eu-west-2]="Europe (London)"
  [eu-west-3]="Europe (Paris)"
  [il-central-1]="Israel (Tel Aviv)"
  [mx-central-1]="Mexico (Querétaro)"
  [sa-east-1]="South America (São Paulo)"
  [us-east-1]="US East (N. Virginia)"
  [us-east-2]="US East (Ohio)"
  [us-west-1]="US West (N. California)"
  [us-west-2]="US West (Oregon)"
)

# Obtener regiones disponibles en la cuenta
AWS_REGIONS=($(aws ec2 describe-regions \
  --query "Regions[].RegionName" \
  --output text | tr '\t' '\n' | sort))

echo "Elige una región de AWS:"

# Construimos las opciones visibles
OPTIONS=()
for r in "${AWS_REGIONS[@]}"; do
  name="${REGION_NAMES[$r]:-Unknown region}"
  OPTIONS+=("$r – $name")
done

select OPTION in "${OPTIONS[@]}"; do
  if [[ -n "$OPTION" ]]; then
    AWS_REGION="${OPTION%% *}" # Quédate con lo que hay antes del primer espacio
    export AWS_REGION
    echo "✅ Región seleccionada: $AWS_REGION (${REGION_NAMES[$AWS_REGION]})"
    break
  else
    echo "❌ Opción inválida, prueba otra vez."
  fi
done
