# Hefesto Mantenciones

Aplicación privada en español para equipos, agenda técnica, prevención, checklist, incidentes, fotografías, informes imprimibles y QR. Incluye demostración identificada como tal en Sites y distribución portable vacía.

Empieza en [docs/INSTALACION.md](docs/INSTALACION.md). Incluye código completo, Docker/Coolify, adaptadores SQLite/Supabase, SQL, importador/exportador y preparación CSV para Odoo. No requiere ChatGPT en su instalación portable.

## Verificar
Node 24: `node --test tests/*.test.mjs`. Build portable: instalar dependencias de `portable/package.json` en la raíz de una copia y ejecutar `npm run build`. El paquete raíz original corresponde al despliegue Sites. `portable/dist` contiene el cliente ya compilado.

## Monetización propuesta
Instalar una instancia por empresa de servicio y ofrecer configuración inicial, carga de equipos y soporte mensual. Los precios y contratos se definen comercialmente; esta aplicación no automatiza suscripciones ni cobros.

## Despliegue en Coolify (MVP Hefesto)

El compose que Coolify consume es `compose.supabase.yaml`. Traefik, fuera del compose, publica el
dominio y pone TLS; el servicio `taller` queda como gateway interno en el puerto 3000.

Variables obligatorias en Coolify (Resources → Environment Variables):

| Variable | Descripción |
| --- | --- |
| `SUPABASE_URL` | URL pública de tu proyecto Supabase (`https://<ref>.supabase.co`) o interna `http://supabase-kong:8000` si Kong vive en la misma red. |
| `SUPABASE_SECRET_KEY` | Clave `sb_secret_…` (preferida) o `service_role` legacy. Nunca `anon` ni `publishable`. |
| `ADMIN_PASSWORD` | Contraseña del panel admin (mínimo 16 caracteres, aleatoria). |
| `PUBLIC_ORIGIN` | Origen público exacto, p. ej. `https://mantenciones.tu-dominio.cl`. |
| `WORKSHOP_ID` | (Opcional) Identificador de la instancia. Por defecto `main`. |
| `COOKIE_SECURE` | (Opcional) `true` en producción. Por defecto `true`. |

Antes del primer deploy, aplicar **una vez** en SQL Editor de Supabase el archivo
`supabase/migrations/202610130001_hefesto_taller.sql` (crea `hefesto_mantenciones_states` y
`hefesto_mantenciones_sessions`). El servidor usa esas tablas por REST con la clave secreta.

Asignar el dominio al servicio `taller` en Coolify. Si se reutiliza la URL pública de Supabase,
asegurarse de que la lista de hosts permitidos de `portable/storage.mjs` la cubra; hoy acepta
`localhost`, `127.0.0.1`, `supabase-kong` y `kong`.
