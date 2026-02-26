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

echo "Choose how you want to set the password for the postgres user:"
select POSTGRES_PASSWORD_MODE in "Set manually" "Generate automatically"; do
    case "$POSTGRES_PASSWORD_MODE" in
        "Set manually")
            while true; do
                read -s -p "Enter the password for the postgres user: " POSTGRES_PASSWORD
                echo
                read -s -p "Confirm the password for the postgres user: " POSTGRES_PASSWORD_CONFIRM
                echo

                if [[ -z "$POSTGRES_PASSWORD" ]]; then
                    echo "❌ The password cannot be empty."
                    continue
                fi

                if [[ "$POSTGRES_PASSWORD" == "$POSTGRES_PASSWORD_CONFIRM" ]]; then
                    echo "Password confirmed. Continuing..."
                    break
                else
                    echo "Passwords do not match. Please try again."
                fi
            done
            break
            ;;
        "Generate automatically")
            POSTGRES_PASSWORD=$(generate_strong_password)
            echo "A strong password was generated automatically."
            break
            ;;
        *)
            echo "Invalid option, please select 1 or 2."
            ;;
    esac
done

# Run ALTER USER safely.
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

if [[ "$POSTGRES_PASSWORD_MODE" == "Generate automatically" ]]; then
    export PENDING_SECRET_POSTGRES_USER_PASSWORD="$POSTGRES_PASSWORD"
    echo "Automatic password prepared. The secret will be created from the main script."
fi

echo "✅ The postgres user password has been set successfully."
