# ARETE Admin — API + Web Dashboard

A web admin console for the ARETE fitness platform, built on **Node.js + Express + PostgreSQL**.
The same API is designed to back the Flutter mobile app later (via its repository seam).

```
admin/
├── server/            # Express API + static file server
│   ├── db/schema.sql  # PostgreSQL schema (tables, enums, indexes)
│   ├── scripts/       # migrate.js, seed.js
│   ├── src/
│   │   ├── routes/    # auth.js, admin.js
│   │   ├── middleware/auth.js   # JWT + role guard
│   │   ├── db.js app.js server.js
│   └── docker-compose.yml       # local PostgreSQL
└── web/               # HTML/CSS/JS dashboard (served by Express)
    ├── index.html     # login
    ├── dashboard.html # overview / members / trainers / plans
    ├── app.js styles.css
```

## Deploy to your server (interactive installer)

On the target server (e.g. `161.97.78.116`, no domain needed), clone the repo and run:

```bash
cd admin/server
sudo bash install.sh      # sudo enables the systemd + firewall steps
```

The installer **asks you** for everything and does the rest:

1. **HTTP port** (e.g. `4000`) and bind address (`0.0.0.0` = reachable on the public IP)
2. **PostgreSQL** host / port / database / user / **password**
3. **JWT secret** (press Enter to auto-generate a strong one) + token lifetime
4. **Admin email + password** (the account you'll log in with)

Then it writes `.env` (chmod 600), runs `npm install`, optionally **creates the database & role**
(asks for a PostgreSQL superuser), applies the schema, creates the admin user, optionally loads demo
data, and optionally installs a **systemd service** (`arete-admin`) so it starts on boot — and opens the
port in `ufw`.

When it finishes you'll see:

```
Admin console:  http://161.97.78.116:4000
Sign in with:   admin@arete.fit
```

Manage the service:

```bash
systemctl status arete-admin
journalctl -u arete-admin -f      # live logs
sudo systemctl restart arete-admin
```

> Prerequisite: Node 18+ and a reachable PostgreSQL. If PostgreSQL isn't installed:
> `sudo apt install -y postgresql`. The installer can create the DB and role for you.
> Plain HTTP over an IP is fine to start; add HTTPS via a reverse proxy once you have a domain.

## Run it locally

Requires Node 18+ and Docker (for PostgreSQL).

```bash
cd admin/server
cp .env.example .env               # adjust JWT_SECRET etc.
docker compose up -d               # starts PostgreSQL on :5432
npm install
npm run reset                      # applies schema.sql + seeds sample data
npm start                          # API + dashboard on http://localhost:4000
```

Open **http://localhost:4000** and sign in with the seeded admin:

```
admin@arete.fit / admin123
```

> No Docker? Point `DATABASE_URL` in `.env` at any PostgreSQL instance, then
> `npm run reset && npm start`.

## What works now

- **Auth:** `POST /api/auth/login` → JWT (admin-only for the console). Passwords are bcrypt-hashed.
- **Overview:** total/active members, expiring soon, MRR, trainers, sessions today, tier breakdown, 12-week growth chart.
- **Members:** searchable, paginated list with tier / trainer / status / renewal.
- **Trainers:** roster with client counts and ratings.
- **Plans:** the plan library.

## API (all under `/api`, JWT required except login)

| Method | Path | Purpose |
|--------|------|---------|
| POST  | `/auth/login` | Admin sign-in → JWT |
| GET   | `/admin/overview` | Dashboard KPIs |
| GET   | `/admin/members` | List (`?query=&status=&page=`) |
| GET   | `/admin/members/:id` | Member detail |
| PATCH | `/admin/members/:id` | Update status / tier / trainer |
| GET   | `/admin/trainers` | Trainer roster |
| GET   | `/admin/plans` | Plan library |
| GET   | `/admin/stats/growth` | Weekly sign-ups |
| GET   | `/admin/stats/revenue` | Monthly revenue |

## Next steps

- Member detail drawer + inline edit actions in the UI.
- Member/trainer endpoints for the mobile app, then point the Flutter
  `AuthRepository`/`ProfileRepository` at this API.
- Payments & invoices, roles & audit-log views.

## Security notes

This is a starter. Before production: rotate `JWT_SECRET`, add rate limiting and
HTTPS, validate/enforce input with a schema validator, and add refresh tokens.
