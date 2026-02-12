#!/usr/bin/env bash
set -euo pipefail

echo "🔧 Configurando PostgreSQL para escuchar en red..."

# Detectar paths (Ubuntu/Debian)
PG_CONF=$(ls /etc/postgresql/*/main/postgresql.conf | head -n1)
PG_HBA=$(ls /etc/postgresql/*/main/pg_hba.conf | head -n1)

if [[ ! -f "$PG_CONF" || ! -f "$PG_HBA" ]]; then
  echo "❌ No se encontraron archivos de configuración de PostgreSQL"
  exit 1
fi

echo "📄 postgresql.conf: $PG_CONF"
echo "📄 pg_hba.conf:     $PG_HBA"

# Backups
sudo cp "$PG_CONF" "${PG_CONF}.bak.$(date +%F_%H-%M-%S)"
sudo cp "$PG_HBA"  "${PG_HBA}.bak.$(date +%F_%H-%M-%S)"

echo "🗂 Backups creados"

# ---- listen_addresses = '*' ----
if sudo grep -Eq "^\s*listen_addresses\s*=" "$PG_CONF"; then
  sudo sed -i "s|^\s*listen_addresses\s*=.*|listen_addresses = '*'|" "$PG_CONF"
else
  echo "listen_addresses = '*'" | sudo tee -a "$PG_CONF" >/dev/null
fi

echo "✅ listen_addresses configurado"

# ---- pg_hba.conf rule ----
HBA_RULE="host    all    all    0.0.0.0/0    scram-sha-256"

if ! sudo grep -Fxq "$HBA_RULE" "$PG_HBA"; then
  echo "$HBA_RULE" | sudo tee -a "$PG_HBA" >/dev/null
  echo "✅ Regla pg_hba.conf añadida"
else
  echo "ℹ️ La regla ya existe en pg_hba.conf"
fi

# ---- Reinicio / reload ----
echo "🔁 Reiniciando PostgreSQL..."
sudo systemctl restart postgresql

echo "🎉 PostgreSQL configurado correctamente"
