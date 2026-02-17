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

CREATE TABLE IF NOT EXISTS infranettone.projects (
    project_id VARCHAR(255) PRIMARY KEY
);

CREATE TABLE IF NOT EXISTS infranettone.clients (
    client_id VARCHAR(255) PRIMARY KEY
);

CREATE TABLE IF NOT EXISTS infranettone.projects_clients (
    project_id VARCHAR(255) NOT NULL,
    client_id VARCHAR(255) NOT NULL,
    PRIMARY KEY (project_id, client_id),
    CONSTRAINT fk_projects_clients_project
        FOREIGN KEY (project_id)
        REFERENCES infranettone.projects (project_id),
    CONSTRAINT fk_projects_clients_client
        FOREIGN KEY (client_id)
        REFERENCES infranettone.clients (client_id)
);

INSERT INTO infranettone.projects (project_id)
VALUES
    ('project_test_1'),
    ('project_test_2')
ON CONFLICT (project_id) DO NOTHING;

INSERT INTO infranettone.clients (client_id)
VALUES
    ('client_test_1'),
    ('client_test_2'),
    ('client_test_3'),
    ('client_test_4')
ON CONFLICT (client_id) DO NOTHING;

INSERT INTO infranettone.projects_clients (project_id, client_id)
VALUES
    ('project_test_1', 'client_test_1'),
    ('project_test_1', 'client_test_2'),
    ('project_test_1', 'client_test_3'),
    ('project_test_1', 'client_test_4'),
    ('project_test_2', 'client_test_1'),
    ('project_test_2', 'client_test_2'),
    ('project_test_2', 'client_test_3'),
    ('project_test_2', 'client_test_4')
ON CONFLICT (project_id, client_id) DO NOTHING;
EOF
echo -e "${CYAN}End of block Create and configure PostgreSQL database.${NC}"
# End of block Create and configure PostgreSQL database.
