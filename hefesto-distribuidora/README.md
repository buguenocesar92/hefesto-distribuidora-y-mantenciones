# Hefesto Distribuidora
Aplicación mayorista B2B: catálogo, listas por cliente, pedidos, cupos de crédito, preparación, inventario, compras parciales, proveedores, cobranza y rutas con constancia de entrega.

Comienza por `docs/INSTALACION.md`. Supabase/Coolify: `compose.supabase.yaml`. Alternativa SQLite: `compose.yaml`.
Código de negocio independiente: `lib/domain.ts`; adaptador Sites/D1: `app/api/store`; adaptador portable: `portable/server.mjs`.

Pruebas: `node --test tests/*.test.mjs`.
Frontend portable: `node node_modules/vite/bin/vite.js build --config portable/vite.config.mts`.
