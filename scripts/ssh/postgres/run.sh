generate_strong_password() {
    local generated_password
    if ! command -v openssl >/dev/null 2>&1; then
        echo "❌ OpenSSL is required to generate an automatic password." >&2
        return 1
    fi
    while true; do
        generated_password=$(openssl rand -base64 48)
        if [[ "$generated_password" =~ [A-Z] && "$generated_password" =~ [a-z] && "$generated_password" =~ [0-9] && "$generated_password" =~ [\!\@\#\%\^\*\_\=\+\.\-] ]]; then
            echo "$generated_password"
            return 0
        fi
    done
}

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
    echo "Choose how you want to set the password for the postgres user:"
    select POSTGRES_REMOTE_PASSWORD_MODE in "Set manually" "Generate automatically"; do
        case "$POSTGRES_REMOTE_PASSWORD_MODE" in
            "Set manually")
                while true; do
                    read -s -p "Enter the password for the postgres user: " POSTGRES_REMOTE_PASSWORD
                    echo
                    read -s -p "Confirm the password for the postgres user: " POSTGRES_REMOTE_PASSWORD_CONFIRM
                    echo

                    if [[ -z "$POSTGRES_REMOTE_PASSWORD" ]]; then
                        echo "❌ The password cannot be empty."
                        continue
                    fi

                    if [[ "$POSTGRES_REMOTE_PASSWORD" == "$POSTGRES_REMOTE_PASSWORD_CONFIRM" ]]; then
                        echo "Password confirmed. Continuing..."
                        break
                    else
                        echo "Passwords do not match. Please try again."
                    fi
                done
                break
                ;;
            "Generate automatically")
                POSTGRES_REMOTE_PASSWORD=$(generate_strong_password)
                echo "A strong password was generated automatically."
                export PENDING_SECRET_POSTGRES_USER_PASSWORD="$POSTGRES_REMOTE_PASSWORD"
                break
                ;;
            *)
                echo "Invalid option, please select 1 or 2."
                ;;
        esac
    done

    ssh -i $PEM_KEY_REALPATH ubuntu@$PUBLIC_IP "mkdir -p ~/$APP_NAME"
    scp -i "$PEM_KEY_REALPATH" "scripts/ssh/postgres/alter-user.sh" ubuntu@"$PUBLIC_IP":~/$APP_NAME
    scp -i "$PEM_KEY_REALPATH" "scripts/ssh/postgres/open-listener-and-hba.sh" ubuntu@"$PUBLIC_IP":~/$APP_NAME
    printf '%s\n' "$POSTGRES_REMOTE_PASSWORD" | ssh -T -i $PEM_KEY_REALPATH ubuntu@$PUBLIC_IP "POSTGRES_PASSWORD_MODE='$POSTGRES_REMOTE_PASSWORD_MODE' bash ~/$APP_NAME/alter-user.sh --password-from-stdin"
    ssh -t -i $PEM_KEY_REALPATH ubuntu@$PUBLIC_IP "bash ~/$APP_NAME/open-listener-and-hba.sh"
fi

if [[ "$DOCKERFILE_PATH" == *postgres* ]]; then
    echo "¿Quieres establecer una contraseña al usuario postgres?"
    select SET_POSTGRES_PASSWORD_DOCKER in "Sí" "No"; do
        echo "Has elegido $SET_POSTGRES_PASSWORD_DOCKER."
        break
    done
else
    SET_POSTGRES_PASSWORD_DOCKER="No"
fi

if [[ "$SET_POSTGRES_PASSWORD_DOCKER" == "Sí" ]]; then
    source scripts/ssh/postgres/alter-user-docker.sh
fi
