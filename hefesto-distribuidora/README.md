# Hefesto Distribuidora
Aplicación mayorista B2B: catálogo, listas por cliente, pedidos, cupos de crédito, preparación, inventario, compras parciales, proveedores, cobranza y rutas con constancia de entrega.

Comienza por `docs/INSTALACION.md`. Supabase/Coolify: `compose.supabase.yaml`. Alternativa SQLite: `compose.yaml`.
Código de negocio independiente: `lib/domain.ts`; adaptador Sites/D1: `app/api/store`; adaptador portable: `portable/server.mjs`.

Pruebas: `node --test tests/*.test.mjs`.
Frontend portable: `node node_modules/vite/bin/vite.js build --config portable/vite.config.mts`.

## Despliegue en Coolify (MVP Hefesto)

El compose que Coolify consume es `compose.supabase.yaml`. Traefik, fuera del compose, publica el
dominio y pone TLS; el servicio `taller` queda como gateway interno en el puerto 3000.

Variables obligatorias en Coolify (Resources → Environment Variables):

| Variable | Descripción |
| --- | --- |
| `SUPABASE_URL` | URL pública de tu proyecto Supabase (`https://<ref>.supabase.co`) o interna `http://supabase-kong:8000` si Kong vive en la misma red. |
| `SUPABASE_SECRET_KEY` | Clave `sb_secret_…` (preferida) o `service_role` legacy. Nunca `anon` ni `publishable`. |
| `ADMIN_PASSWORD` | Contraseña del panel admin (mínimo 16 caracteres, aleatoria). |
| `PUBLIC_ORIGIN` | Origen público exacto, p. ej. `https://distribuidora.tu-dominio.cl`. |
| `WORKSHOP_ID` | (Opcional) Identificador de la instancia. Por defecto `main`. |
| `COOKIE_SECURE` | (Opcional) `true` en producción. Por defecto `true`. |

Antes del primer deploy, aplicar **una vez** en SQL Editor de Supabase el archivo
`supabase/migrations/202610130001_hefesto_taller.sql` (crea `hefesto_distribuidora_states` y
`hefesto_distribuidora_sessions`). El servidor usa esas tablas por REST con la clave secreta.

Asignar el dominio al servicio `taller` en Coolify. Si se reutiliza la URL pública de Supabase,
asegurarse de que la lista de hosts permitidos de `portable/storage.mjs` la cubra; hoy acepta
`localhost`, `127.0.0.1`, `supabase-kong` y `kong`.
