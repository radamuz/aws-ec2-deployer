#!/usr/bin/env bash

# ❗ NO usamos set -e para poder mostrar errores
set -u

API_URL="https://api.servidoresdns.net:54321/hosting/api/soap/index.php"

echo "🔍 [DEBUG] Script iniciado"
echo "🔍 [DEBUG] Endpoint: $API_URL"
echo

# --------- PARÁMETROS ----------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --login)  LOGIN="$2"; shift 2 ;;
    --apikey) APIKEY="$2"; shift 2 ;;
    --domain) DOMAIN="$2"; shift 2 ;;
    --dns)    DNS="$2"; shift 2 ;;
    --type)   TYPE="$2"; shift 2 ;;
    --value)  VALUE="$2"; shift 2 ;;
    *)
      echo "❌ [ERROR] Parámetro desconocido: $1"
      exit 1
      ;;
  esac
done

# --------- VALIDACIONES ----------
echo "🔍 [DEBUG] Validando parámetros…"
for VAR in LOGIN APIKEY DOMAIN DNS TYPE VALUE; do
  if [[ -z "${!VAR:-}" ]]; then
    echo "❌ [ERROR] Falta el parámetro --${VAR,,}"
    exit 1
  fi
  echo "  ✔ $VAR = ${!VAR}"
done
echo

# --------- AUTH ----------
echo "🔍 [DEBUG] Generando Authorization header…"
AUTH_RAW="${LOGIN}:${APIKEY}"
AUTH_B64=$(printf "%s" "$AUTH_RAW" | base64)

echo "  LOGIN:APIKEY = $AUTH_RAW"
echo "  Base64       = $AUTH_B64"
echo

# --------- SOAP XML ----------
echo "🔍 [DEBUG] Construyendo SOAP XML…"
read -r -d '' SOAP_BODY <<EOF
<?xml version="1.0" encoding="ISO-8859-1"?>
<soapenv:Envelope
  xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
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

echo "📄 [DEBUG] SOAP REQUEST:"
echo "----------------------------------------"
echo "$SOAP_BODY"
echo "----------------------------------------"
echo

# --------- REQUEST ----------
echo "📡 [DEBUG] Enviando petición SOAP…"

HTTP_CODE=$(curl -v \
  -o response.xml \
  -w "%{http_code}" \
  -X POST "$API_URL" \
  -H "Authorization: Basic $AUTH_B64" \
  -H "Content-Type: text/xml; charset=ISO-8859-1" \
  --data "$SOAP_BODY" \
  2>curl_debug.log)

echo
echo "🔍 [DEBUG] HTTP status code: $HTTP_CODE"
echo

echo "📄 [DEBUG] CURL verbose log:"
echo "----------------------------------------"
cat curl_debug.log
echo "----------------------------------------"
echo

echo "📄 [DEBUG] SOAP RESPONSE:"
echo "----------------------------------------"
cat response.xml
echo "----------------------------------------"
echo

# --------- RESULTADO ----------
if [[ "$HTTP_CODE" != "200" ]]; then
  echo "❌ [ERROR] HTTP $HTTP_CODE (fallo de transporte)"
  exit 1
fi

if grep -q "<errorCode xsi:type=\"xsd:int\">0</errorCode>" response.xml; then
  echo "✅ [OK] Registro DNS creado correctamente"
else
  echo "❌ [ERROR] La API respondió con error SOAP"
  echo "👉 Revisa <errorCode> y <errorMsg> arriba"
  exit 1
fi
