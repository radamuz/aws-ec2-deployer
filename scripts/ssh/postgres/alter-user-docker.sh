echo "Has elegido establecer una contraseña para el usuario postgres."

while true; do
    read -s -p "Introduce la contraseña para el usuario postgres: " POSTGRES_PASSWORD
    echo
    read -s -p "Confirma la contraseña para el usuario postgres: " POSTGRES_PASSWORD_CONFIRM
    echo

    if [[ -z "$POSTGRES_PASSWORD" ]]; then
        echo "❌ La contraseña no puede estar vacía."
        continue
    fi

    if [[ "$POSTGRES_PASSWORD" == "$POSTGRES_PASSWORD_CONFIRM" ]]; then
        echo "Contraseña confirmada. Continuamos..."
        break
    else
        echo "Las contraseñas no coinciden. Por favor, inténtalo de nuevo."
    fi
done

# Ejecutar ALTER USER de forma segura
docker run --rm \
  -i \
  -e PGPASSWORD=changeme \
  -e POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
  alpine/psql:latest \
  -h "$PUBLIC_IP" \
  -U postgres \
  -v POSTGRES_PASSWORD="$POSTGRES_PASSWORD" <<'EOF'
ALTER USER postgres PASSWORD :'POSTGRES_PASSWORD';
EOF


echo "✅ Contraseña del usuario postgres establecida correctamente."
