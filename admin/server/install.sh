#!/usr/bin/env bash
#
# ARETE Admin — interactive installer.
# Prompts for the port and credentials, writes .env, installs dependencies,
# (optionally) creates the database, applies the schema, creates the admin
# user, and (optionally) installs a systemd service so it runs on boot.
#
# Run from the admin/server directory:
#     bash install.sh
# For the systemd + firewall steps you'll want root:
#     sudo bash install.sh
#
set -u

# ---------- helpers ----------
BOLD="\033[1m"; DIM="\033[2m"; GREEN="\033[32m"; YELLOW="\033[33m"; RED="\033[31m"; RESET="\033[0m"
say()  { printf "%b\n" "$1"; }
hr()   { printf "%b\n" "${DIM}────────────────────────────────────────────${RESET}"; }
ask()  { # ask "Prompt" "default" -> echoes answer
  local prompt="$1" def="${2:-}" ans
  if [ -n "$def" ]; then read -r -p "$(printf "%b" "$prompt [${def}]: ")" ans; echo "${ans:-$def}";
  else read -r -p "$(printf "%b" "$prompt: ")" ans; echo "$ans"; fi
}
ask_secret() { # ask_secret "Prompt" -> echoes typed secret (hidden)
  local prompt="$1" ans; read -r -s -p "$(printf "%b" "$prompt: ")" ans; echo >&2; echo "$ans"
}
yesno() { # yesno "Prompt" "Y|N default" -> returns 0 for yes
  local prompt="$1" def="${2:-N}" ans
  read -r -p "$(printf "%b" "$prompt $([ "$def" = Y ] && echo '[Y/n]' || echo '[y/N]'): ")" ans
  ans="${ans:-$def}"; case "$ans" in [Yy]*) return 0;; *) return 1;; esac
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

say "${BOLD}ARETE Admin — installer${RESET}"
say "${DIM}Server IP is auto-detected below; press Enter to accept the defaults in brackets.${RESET}"
hr

# ---------- detect node ----------
if ! command -v node >/dev/null 2>&1; then
  say "${RED}Node.js is not installed.${RESET} Install Node 18+ first, then re-run."
  say "  Ubuntu:  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - && sudo apt install -y nodejs"
  exit 1
fi
NODE_BIN="$(command -v node)"
say "Using Node: ${GREEN}$($NODE_BIN --version)${RESET} ($NODE_BIN)"

# best-effort public IP for the final URL / hints
DETECTED_IP="$(hostname -I 2>/dev/null | awk '{print $1}')"
DETECTED_IP="${DETECTED_IP:-161.97.78.116}"

hr
say "${BOLD}1) Network${RESET}"
HTTP_PORT="$(ask "HTTP port to serve the admin on" "4000")"
BIND_HOST="$(ask "Bind address (0.0.0.0 = all interfaces)" "0.0.0.0")"
say "${DIM}How will people reach this server? Enter an IP address (e.g. 161.97.78.116) or a domain name (e.g. admin.myclub.com).${RESET}"
PUBLIC_ADDR="$(ask "Public IP or domain name" "$DETECTED_IP")"

# Build the public URL: omit :port for 80/443, use https for 443.
case "$HTTP_PORT" in
  80)  BASE_URL="http://${PUBLIC_ADDR}" ;;
  443) BASE_URL="https://${PUBLIC_ADDR}" ;;
  *)   BASE_URL="http://${PUBLIC_ADDR}:${HTTP_PORT}" ;;
esac

hr
say "${BOLD}2) PostgreSQL connection${RESET}"
DB_HOST="$(ask "PostgreSQL host" "localhost")"
DB_PORT="$(ask "PostgreSQL port" "5432")"
DB_NAME="$(ask "Database name" "arete")"
DB_USER="$(ask "Database user" "arete")"
DB_PASS="$(ask_secret "Database password")"
while [ -z "$DB_PASS" ]; do DB_PASS="$(ask_secret "Database password (cannot be empty)")"; done

hr
say "${BOLD}3) Security${RESET}"
DEFAULT_JWT="$($NODE_BIN -e 'console.log(require("crypto").randomBytes(32).toString("hex"))' 2>/dev/null || echo change-me-$RANDOM$RANDOM)"
JWT_SECRET="$(ask "JWT secret (Enter = use a generated one)" "$DEFAULT_JWT")"
JWT_EXPIRES="$(ask "Token lifetime" "12h")"

hr
say "${BOLD}4) Admin account${RESET}"
ADMIN_EMAIL="$(ask "Admin email" "admin@arete.fit")"
ADMIN_PASS="$(ask_secret "Admin password")"
while [ ${#ADMIN_PASS} -lt 6 ]; do ADMIN_PASS="$(ask_secret "Admin password (min 6 chars)")"; done

# URL-encode the DB password for the connection string
DB_PASS_ENC="$($NODE_BIN -e 'process.stdout.write(encodeURIComponent(process.argv[1]))' "$DB_PASS")"
DATABASE_URL="postgres://${DB_USER}:${DB_PASS_ENC}@${DB_HOST}:${DB_PORT}/${DB_NAME}"

# ---------- write .env ----------
hr
if [ -f .env ] && ! yesno "${YELLOW}.env already exists — overwrite?${RESET}" "N"; then
  say "Keeping existing .env."
else
  cat > .env <<EOF
PORT=${HTTP_PORT}
HOST=${BIND_HOST}
PUBLIC_URL=${BASE_URL}
DATABASE_URL=${DATABASE_URL}
JWT_SECRET=${JWT_SECRET}
JWT_EXPIRES_IN=${JWT_EXPIRES}
ADMIN_EMAIL=${ADMIN_EMAIL}
ADMIN_PASSWORD=${ADMIN_PASS}
EOF
  chmod 600 .env
  say "${GREEN}Wrote .env${RESET} (permissions 600)."
fi

# ---------- npm install ----------
hr
say "${BOLD}Installing dependencies…${RESET}"
npm install --omit=dev --no-audit --no-fund || { say "${RED}npm install failed${RESET}"; exit 1; }

# ---------- optional: create database + role ----------
hr
if yesno "${BOLD}Create the database and role now?${RESET} ${DIM}(needs a PostgreSQL superuser)${RESET}" "N"; then
  SUPER="$(ask "PostgreSQL superuser" "postgres")"
  PSQL_BASE=""
  if command -v sudo >/dev/null 2>&1 && id "$SUPER" >/dev/null 2>&1; then
    PSQL_BASE="sudo -u $SUPER psql -h $DB_HOST -p $DB_PORT"
  else
    SUPER_PW="$(ask_secret "Password for $SUPER")"
    export PGPASSWORD="$SUPER_PW"
    PSQL_BASE="psql -U $SUPER -h $DB_HOST -p $DB_PORT"
  fi
  say "Creating role and database (existing ones are left as-is)…"
  $PSQL_BASE -v ON_ERROR_STOP=0 -d postgres -c \
    "DO \$\$ BEGIN CREATE ROLE \"${DB_USER}\" LOGIN PASSWORD '${DB_PASS}'; EXCEPTION WHEN duplicate_object THEN RAISE NOTICE 'role exists'; END \$\$;" || true
  $PSQL_BASE -v ON_ERROR_STOP=0 -d postgres -tc \
    "SELECT 1 FROM pg_database WHERE datname='${DB_NAME}'" | grep -q 1 \
    || $PSQL_BASE -d postgres -c "CREATE DATABASE \"${DB_NAME}\" OWNER \"${DB_USER}\";"
  unset PGPASSWORD
  say "${GREEN}Database ready.${RESET}"
else
  say "Skipping DB creation — make sure ${BOLD}${DB_NAME}${RESET} exists and ${BOLD}${DB_USER}${RESET} can connect."
fi

# ---------- migrate + admin ----------
hr
say "${BOLD}Applying schema…${RESET}"
npm run migrate || { say "${RED}Migration failed — check the DB connection.${RESET}"; exit 1; }

say "${BOLD}Creating the admin user…${RESET}"
ADMIN_EMAIL="$ADMIN_EMAIL" ADMIN_PASSWORD="$ADMIN_PASS" npm run create-admin || exit 1

if yesno "Load ${YELLOW}sample demo data${RESET}? ${DIM}(WIPES existing rows — dev only)${RESET}" "N"; then
  npm run seed || true
fi

# ---------- optional: systemd service ----------
hr
SERVICE_INSTALLED=0
if command -v systemctl >/dev/null 2>&1 && yesno "${BOLD}Install a systemd service${RESET} (auto-start on boot)?" "Y"; then
  RUN_USER="${SUDO_USER:-$(whoami)}"
  UNIT=/etc/systemd/system/arete-admin.service
  TMP_UNIT="$(mktemp)"
  cat > "$TMP_UNIT" <<EOF
[Unit]
Description=ARETE Admin API
After=network.target postgresql.service

[Service]
Type=simple
User=${RUN_USER}
WorkingDirectory=${SCRIPT_DIR}
EnvironmentFile=${SCRIPT_DIR}/.env
ExecStart=${NODE_BIN} ${SCRIPT_DIR}/src/server.js
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
  if [ "$(id -u)" -eq 0 ]; then
    mv "$TMP_UNIT" "$UNIT"
    systemctl daemon-reload
    systemctl enable --now arete-admin
    SERVICE_INSTALLED=1
    say "${GREEN}Service installed and started.${RESET}  Manage with: systemctl status arete-admin"
  else
    say "${YELLOW}Not root — wrote unit to $TMP_UNIT.${RESET} Install it with:"
    say "  sudo mv $TMP_UNIT $UNIT && sudo systemctl daemon-reload && sudo systemctl enable --now arete-admin"
  fi
fi

# ---------- optional: firewall ----------
if command -v ufw >/dev/null 2>&1 && yesno "Open port ${HTTP_PORT} in ufw?" "Y"; then
  if [ "$(id -u)" -eq 0 ]; then ufw allow "${HTTP_PORT}/tcp" || true; else sudo ufw allow "${HTTP_PORT}/tcp" || true; fi
fi

# ---------- done ----------
hr
say "${GREEN}${BOLD}Done!${RESET}"
say "Admin console:  ${BOLD}${BASE_URL}${RESET}"
say "Sign in with:   ${BOLD}${ADMIN_EMAIL}${RESET}"
if [ "$SERVICE_INSTALLED" -eq 1 ]; then
  say "Service:        ${DIM}systemctl status arete-admin | journalctl -u arete-admin -f${RESET}"
else
  say "Start manually: ${DIM}cd ${SCRIPT_DIR} && npm start${RESET}"
fi
say "${DIM}Note: this serves plain HTTP over an IP. For production put it behind HTTPS (a reverse proxy) once you have a domain.${RESET}"
