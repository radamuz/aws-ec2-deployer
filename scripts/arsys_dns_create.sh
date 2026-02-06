#!/usr/bin/env bash
set -u

API_URL="https://api.servidoresdns.net:54321/hosting/api/soap/index.php"

# ---------- PARÁMETROS ----------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --login)  LOGIN="$2"; shift 2 ;;
    --apikey) APIKEY="$2"; shift 2 ;;
    --domain) DOMAIN="$2"; shift 2 ;;
    --dns)    DNS="$2"; shift 2 ;;
    --type)   TYPE="$2"; shift 2 ;;
    --value)  VALUE="$2"; shift 2 ;;
    *) echo "❌ Parámetro desconocido: $1"; exit 1 ;;
  esac
done

# ---------- VALIDACIONES ----------
for VAR in LOGIN APIKEY DOMAIN DNS TYPE VALUE; do
  [[ -z "${!VAR:-}" ]] && echo "❌ Falta --${VAR,,}" && exit 1
done

# ---------- AUTH ----------
AUTH_B64=$(printf "%s:%s" "$LOGIN" "$APIKEY" | base64)

# ---------- CREATE DNS ----------
SOAP_CREATE=$(cat <<EOF
<?xml version="1.0" encoding="ISO-8859-1"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
                  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                  xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soapenv:Body>
    <CreateDNSEntry xmlns="CreateDNSEntry">
      <input>
        <domain xsi:type="xsd:string">$DOMAIN</domain>
        <dns xsi:type="xsd:string">$DNS</dns>
        <type xsi:type="xsd:string">$TYPE</type>
        <value xsi:type="xsd:string">$VALUE</value>
      </input>
    </CreateDNSEntry>
  </soapenv:Body>
</soapenv:Envelope>
EOF
)

HTTP_CODE=$(curl -s \
  -o response_create.xml \
  -w "%{http_code}" \
  -H "Authorization: Basic $AUTH_B64" \
  -H "Content-Type: text/xml; charset=ISO-8859-1" \
  --data "$SOAP_CREATE" \
  "$API_URL")

if [[ "$HTTP_CODE" != "200" ]]; then
  echo "❌ Error HTTP al crear el registro ($HTTP_CODE)"
  exit 1
fi

if ! grep -q "<errorCode xsi:type=\"xsd:int\">0</errorCode>" response_create.xml; then
  echo "❌ Error SOAP al crear el registro DNS"
  grep -E "<errorCode>|<errorMsg>" response_create.xml
  exit 1
fi

# ---------- VERIFY DNS ----------
SOAP_INFO=$(cat <<EOF
<?xml version="1.0" encoding="ISO-8859-1"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
                  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                  xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soapenv:Body>
    <InfoDNSZone xmlns="InfoDNSZone">
      <input>
        <domain xsi:type="xsd:string">$DOMAIN</domain>
      </input>
    </InfoDNSZone>
  </soapenv:Body>
</soapenv:Envelope>
EOF
)

curl -s \
  -o response_info.xml \
  -H "Authorization: Basic $AUTH_B64" \
  -H "Content-Type: text/xml; charset=ISO-8859-1" \
  --data "$SOAP_INFO" \
  "$API_URL"

if grep -q "<name xsi:type=\"xsd:string\">$DNS</name>" response_info.xml \
   && grep -q "<type xsi:type=\"xsd:string\">$TYPE</type>" response_info.xml \
   && grep -q "<value xsi:type=\"xsd:string\">$VALUE</value>" response_info.xml; then
  echo "✅ Registro DNS creado y verificado correctamente"
  echo "➡️ $TYPE $DNS → $VALUE"
else
  echo "⚠️ Registro creado pero NO encontrado en la zona DNS"
  echo "👉 Puede ser retraso de propagación interna"
  exit 1
fi
