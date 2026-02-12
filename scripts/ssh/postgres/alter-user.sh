echo "Has elegido establecer una contraseña para el usuario postgres."

while true; do
    read -s -p "Introduce la contraseña para el usuario postgres: " POSTGRES_PASSWORD
    echo
    read -s -p "Confirma la contraseña para el usuario postgres: " POSTGRES_PASSWORD_CONFIRM
    echo

    if [[ "$POSTGRES_PASSWORD" == "$POSTGRES_PASSWORD_CONFIRM" ]]; then
        echo "Contraseña confirmada. Continuamos..."
        export POSTGRES_PASSWORD
        break
    else
        echo "Las contraseñas no coinciden. Por favor, inténtalo de nuevo."
    fi
done