if [[ "$USER_DATA_FILE" == "postgres.arm64.sh" ]]; then
    echo "¿Quieres establecer una contraseña al usuario postgres?"
    select SET_POSTGRES_PASSWORD in "Sí" "No"; do
        echo "Has elegido $SET_POSTGRES_PASSWORD."
        break
    done
else
    SET_POSTGRES_PASSWORD="No"
fi

if [[ "$SET_POSTGRES_PASSWORD" == "Sí" ]]; then
    ssh -i $PEM_KEY_REALPATH ubuntu@$PUBLIC_IP "mkdir -p ~/$APP_NAME"
    scp -i "$PEM_KEY_REALPATH" "scripts/ssh/postgres/alter-user.sh" ubuntu@"$PUBLIC_IP":~/$APP_NAME
    scp -i "$PEM_KEY_REALPATH" "scripts/ssh/postgres/open-listener-and-hba.sh" ubuntu@"$PUBLIC_IP":~/$APP_NAME
    ssh -t -i $PEM_KEY_REALPATH ubuntu@$PUBLIC_IP "bash ~/$APP_NAME/alter-user.sh"
    ssh -t -i $PEM_KEY_REALPATH ubuntu@$PUBLIC_IP "bash ~/$APP_NAME/open-listener-and-hba.sh"
fi
