#!/bin/bash

set -euo pipefail

DOCKER_GID="$(getent group docker | cut -d: -f3 || true)"
if [[ -z "${DOCKER_GID}" ]]; then
  DOCKER_GID="$(stat -c '%g' /var/run/docker.sock 2>/dev/null || true)"
fi

if [[ -z "${DOCKER_GID}" ]]; then
  echo "No se pudo detectar el GID de docker (grupo docker ni /var/run/docker.sock)." >&2
  exit 1
fi

DOCKER_GID="${DOCKER_GID}" docker compose -f main/docker-compose.yml up --build -d

docker exec -it infranettone-aws-ec2-deployer /bin/bash
