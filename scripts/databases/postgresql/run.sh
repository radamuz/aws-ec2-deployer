# Start of block Set a password for the infranettone database user.
echo -e "${CYAN}Start of block Set a password for the infranettone database user.${NC}"
while true; do
    read -s -p "Enter the password for the user infranettone: " INFRANETTONE_PASSWORD
    echo
    read -s -p "Confirm the password for the user infranettone: " INFRANETTONE_PASSWORD_CONFIRM
    echo

    if [[ -z "$INFRANETTONE_PASSWORD" ]]; then
        echo "❌ The password cannot be empty."
        continue
    fi

    if [[ "$INFRANETTONE_PASSWORD" == "$INFRANETTONE_PASSWORD_CONFIRM" ]]; then
        echo "Password confirmed. Continuing..."
        break
    else
        echo "Passwords do not match. Please try again."
    fi
done
echo -e "${CYAN}End of block Set a password for the infranettone database user.${NC}"
# End of block Set a password for the infranettone database user.

# Start of block Create and configure PostgreSQL database.
echo -e "${CYAN}Start of block Create and configure PostgreSQL database.${NC}"
docker run --rm \
  -i \
  -e PGPASSWORD="$POSTGRES_PASSWORD" \
  -e INFRANETTONE_PASSWORD="${INFRANETTONE_PASSWORD}" \
  alpine/psql:latest \
  -h "$PUBLIC_IP" \
  -U postgres \
  -v ON_ERROR_STOP=1 \
  -v INFRANETTONE_PASSWORD="${INFRANETTONE_PASSWORD}" <<'EOF'

SELECT format('CREATE USER %I WITH PASSWORD %L', 'infranettone', :'INFRANETTONE_PASSWORD')
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'infranettone')
\gexec

SELECT format('ALTER USER %I WITH PASSWORD %L', 'infranettone', :'INFRANETTONE_PASSWORD')
WHERE EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'infranettone')
\gexec

SELECT format('CREATE DATABASE %I OWNER %I', 'infranettone', 'infranettone')
WHERE NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = 'infranettone')
\gexec

GRANT ALL PRIVILEGES ON DATABASE infranettone TO infranettone;

\connect infranettone

SELECT format('CREATE SCHEMA %I AUTHORIZATION %I', 'infranettone', 'infranettone')
WHERE NOT EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'infranettone')
\gexec

GRANT ALL ON SCHEMA infranettone TO infranettone;
EOF
echo -e "${CYAN}End of block Create and configure PostgreSQL database.${NC}"
# End of block Create and configure PostgreSQL database.
