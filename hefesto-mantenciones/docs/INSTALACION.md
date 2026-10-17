# Hefesto Mantenciones — instalación y traspaso

## Supabase y Coolify
1. Crea o elige tu proyecto Supabase.
2. Ejecuta `supabase/migrations/202610130001_hefesto_taller.sql`. El nombre heredado del archivo no afecta las tablas exclusivas: `hefesto_mantenciones_states` y `hefesto_mantenciones_sessions`.
3. Copia `.env.example` a `.env`. Completa `SUPABASE_URL`, `SUPABASE_SECRET_KEY` (sb_secret o service_role), `WORKSHOP_ID`, `ADMIN_PASSWORD` (16 caracteres mínimo), `PUBLIC_ORIGIN` con tu dominio HTTPS y `COOKIE_SECURE=true`.
4. Ejecuta `docker compose -f compose.supabase.yaml up -d --build`. En Coolify selecciona ese Compose, asigna dominio y puerto interno 3000.
5. Accede con la contraseña de administración. La clave de Supabase se usa exclusivamente en servidor.

SQLite: `docker compose -f compose.yaml up -d --build`. En local, PUBLIC_ORIGIN=http://localhost:3080 y COOKIE_SECURE=false. El volumen conserva la base. Producción requiere HTTPS. Cada app debe tener dominio y puerto de host distintos si comparten servidor; cambia 3080 en Compose según corresponda.

## Migrar datos
Exporta JSON en Portabilidad. La instalación portable empieza vacía, con plantillas genéricas. El ZIP no contiene datos reales.

```
docker compose -f compose.supabase.yaml cp hefesto-mantenciones.json taller:/data/import.json
docker compose -f compose.supabase.yaml exec taller node portable/tools/transfer.mjs validate /data/import.json
docker compose -f compose.supabase.yaml exec taller node portable/tools/transfer.mjs import /data/import.json
```

El nombre técnico `taller` del servicio y WORKSHOP_ID se conserva por compatibilidad del adaptador. Las tablas de cada aplicación están separadas. El importador preserva IDs y rechaza sobrescribir destinos con datos. Usa otro WORKSHOP_ID o volumen para una importación nueva. Detén operaciones durante la migración.

Respaldo: ejecuta `node portable/tools/transfer.mjs export /data/respaldo.json` dentro del servicio y copia el archivo fuera. Conserva copias cifradas independientes. Las fotos están dentro del JSON. Regenera e imprime QR tras cambiar de dominio: apuntan al origen donde se generan y exigen acceso privado.

## Preparar Odoo
`python3 migration/prepare_odoo.py hefesto-mantenciones.json salida-odoo`

Genera CSV de contactos, equipos, visitas, técnicos e incidentes, más JSON completo. Mapear campos y relaciones en la versión destino y probar en una base de ensayo. No incluye addon instalable ni sincronización automática. Fotos, checklists e historial se preservan en JSON y requieren importación adaptada.

## Operación
Crear cliente, técnico y equipo con checklist; programar visita; iniciar; registrar revisión por punto, trabajo, materiales y fotos; cerrar con nombre de receptor y aceptación registrada. Un fallo exige observación y crea incidente. El cierre preventivo calcula próxima fecha desde el día de cierre; no programa visitas automáticamente. Las correctivas no mueven esa fecha. Los costos no son facturas.

## Alcance y verificación
- Administración única, técnicos como registros; sin cuentas independientes o permisos por técnico.
- Recepción manual, sin firma electrónica ni certificación técnica. Plantillas editables creando otras; adaptar protocolos a cada equipo.
- Estado JSON por instancia en Supabase con acceso solo de servidor y RLS; sin Supabase Auth/Storage. Fotos incorporadas, máximo ocho por visita. No es arquitectura para gran volumen de archivos o múltiples empresas simultáneas.
- Sin pagos, facturación SII, correo, WhatsApp, GPS ni Odoo conectados.
- API GET/POST /api/service con revisión para evitar sobrescrituras concurrentes.
- Sitio privado usa D1. Docker puede usar SQLite o Supabase. No se conectó un proyecto real Supabase ni se ejecutó Docker en este entorno.
- Cinco pruebas automáticas y compilaciones verificadas; QA visual en navegador pendiente.
