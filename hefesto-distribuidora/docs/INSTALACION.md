# Hefesto Distribuidora — instalación y traspaso

## Supabase + Coolify
1. Crea un proyecto Supabase o utiliza uno propio.
2. Ejecuta `supabase/migrations/202610130001_hefesto_taller.sql`. El nombre del archivo viene del adaptador base; las tablas que crea son exclusivas de Distribuidora: hefesto_distribuidora_states y hefesto_distribuidora_sessions. No usa las tablas de Taller.
3. Copia `.env.example` a `.env` y completa SUPABASE_URL, SUPABASE_SECRET_KEY, WORKSHOP_ID (identificador de instancia), ADMIN_PASSWORD (mínimo 16 caracteres), PUBLIC_ORIGIN y COOKIE_SECURE=true.
4. Despliega con `docker compose -f compose.supabase.yaml up -d --build`. En Coolify elige ese archivo Compose, asigna dominio HTTPS al servicio y puerto interno 3000.
5. La clave secreta nunca llega al navegador. Se conserva acceso propio de un administrador; no Supabase Auth.

Para SQLite local usa `compose.yaml`, con volumen persistente. En local sin HTTPS configura COOKIE_SECURE=false y PUBLIC_ORIGIN=http://localhost:3080.

## Migrar registros
Exporta el JSON desde Portabilidad en el sitio. El ZIP de código no contiene datos de producción.

```
docker compose -f compose.supabase.yaml cp hefesto-distribuidora.json taller:/data/import.json
docker compose -f compose.supabase.yaml exec taller node portable/tools/transfer.mjs validate /data/import.json
docker compose -f compose.supabase.yaml exec taller node portable/tools/transfer.mjs import /data/import.json
```

El servicio Compose conserva el nombre técnico `taller` por compatibilidad con el adaptador portable. La identidad y tablas de esta aplicación son distintas. El importador rechaza sobrescribir una instancia con operaciones.

Respaldo: usa `transfer.mjs export /data/respaldo.json` y luego `docker compose ... cp taller:/data/respaldo.json ./respaldo.json`. Respalda también tu proyecto Supabase según el plan contratado.

## Odoo
`python3 migration/prepare_odoo.py hefesto-distribuidora.json salida-odoo`

Entrega contactos y productos con IDs externos, stock y pedidos para conciliación, pagos y copia JSON íntegra. Archivos 01–03 son para mapear en el importador de Odoo; 04–06 requieren revisión, no crean asientos ni existencias automáticamente. En este producto no se incluye un módulo Odoo instalable; es un exportador de preparación. Debe validarse contra la versión y módulos del destino.

## API
GET /api/store devuelve {state,revision}. POST recibe {revision,action}. La revisión evita sobrescribir cambios concurrentes; 409 exige recargar antes de repetir. Las acciones están documentadas por su nombre en lib/domain.ts y cubiertas por tests.

## Límites de la versión
- Acceso privado de administración. El catálogo B2B es una vista para preparar pedidos, no un portal público con cuentas de clientes.
- Un documento JSON por instancia, no tablas normalizadas por entidad. Stock por unidad de venta (ej. caja), sin conversión automática a unidades internas ni múltiples bodegas.
- Descuentos por lista; no cotización de impuestos distinta de IVA 19%.
- Rutas manuales, sin geolocalización, optimización de recorridos ni tracking GPS.
- Pagos, referencias de entrega y recepción se registran manualmente. No SII, pasarela, WhatsApp ni correo conectados.
- Cancelación solo antes de despacho y sin pagos. No incluye devoluciones, reembolsos ni notas de crédito fiscales.
- El sitio publicado usa D1; la distribución Docker puede usar Supabase. No se conectó un proyecto real Supabase ni se ejecutó Docker en este entorno.
- Pruebas de código y compilación realizadas. No hubo control de navegador disponible para QA visual.
