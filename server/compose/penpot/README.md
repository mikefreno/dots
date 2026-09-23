# Penpot self-host (pen.freno.me)

Production docker-compose for Penpot, behind the host nginx reverse proxy.

**Auth model:** registration is **disabled**. The only way to get an account is for
the admin to create one via `create-profile` (below). No open signup, no invite
self-serve — you hand out creds to friends/family yourself.

## Services / ports

| Service | Image | Listen |
|---|---|---|
| penpot-frontend | `penpotapp/frontend` | host **8090** → 8080 |
| penpot-backend | `penpotapp/backend` | internal only |
| penpot-exporter | `penpotapp/exporter` | internal only |
| penpot-mcp | `penpotapp/mcp` | internal only (`/mcp/*` via frontend) |
| penpot-postgres | `postgres:15` | internal (data in `./postgres`) |
| penpot-valkey | `valkey/valkey:8.1` | internal |

Assets are stored on the `./assets` bind mount (must be owned by **uid 1001** — the
user the Penpot containers run as). Postgres self-chowns `./postgres` on first start.

## One-time setup

```bash
cd ~/dots/server/compose/penpot

# 1. Start the stack
docker compose up -d

# 2. Make sure the assets dir is writable by the penpot user (uid 1001)
sudo chown -R 1001:1001 assets        # required only for the ./assets bind mount

# 3. Create an admin account for yourself
docker exec -it penpot-backend python3 manage.py create-profile
#    → interactive: fullname, email, password
#    (non-interactive: manage.py create-profile --fullname X --email X --password X)
```

A freshly created profile is `active` by default, so it can log in immediately.

## Reverse proxy (already staged in nginx)

The `pen.freno.me` vhost proxies to `127.0.0.1:8090` with websocket upgrade + large
bodies. Commands below are for the nginx host, not this container:

```bash
# DNS: A record pen.freno.me → server IP (create first)
sudo certbot --nginx -d pen.freno.me     # your existing reload picks it up
sudo systemctl reload nginx
```

Everything is behind HTTPS, so cookie auth is secure.

## Day-to-day

- **Create / update an account** (no self-signup):
  `docker compose exec penpot-backend python3 manage.py create-profile --fullname X --email X --password X`
  or `... update-profile --email x --password y`
- **Access:** https://pen.freno.me — only login page (no register).
- **Upgrade Penpot:**
  `docker compose pull && docker compose up -d`
  (bump `PENPOT_VERSION` in `.env` if you want a specific tag; default `2.16`)
- **Backups:** `docker compose exec penpot-postgres pg_dump -U penpot penpot` +
  the `./assets` directory. Back up `.env` too (contains the secret key).

## Adding SMTP later (optional)

To deliver team-invitation *emails* (friend has no account still needs a manual
`create-profile`), set:
`PENPOT_FLAGS: ... enable-smtp` and the backend envs
`PENPOT_SMTP_HOST/PORT/USERNAME/PASSWORD/TLS`, plus `PENPOT_SMTP_DEFAULT_FROM`.

## Notes / caveats

- No DNS record or `.` yet? The `PENPOT_SECRET_KEY` in `.env` is already generated;
  keep it stable. Regenerating invalidates sessions/invites.
- If the host only has compose v1 (`docker-compose`), swap `docker compose` → `docker-compose` in the systemd unit.