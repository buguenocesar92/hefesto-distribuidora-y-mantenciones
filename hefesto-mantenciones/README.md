# Hefesto Mantenciones

Aplicación privada en español para equipos, agenda técnica, prevención, checklist, incidentes, fotografías, informes imprimibles y QR. Incluye demostración identificada como tal en Sites y distribución portable vacía.

Empieza en [docs/INSTALACION.md](docs/INSTALACION.md). Incluye código completo, Docker/Coolify, adaptadores SQLite/Supabase, SQL, importador/exportador y preparación CSV para Odoo. No requiere ChatGPT en su instalación portable.

## Verificar
Node 24: `node --test tests/*.test.mjs`. Build portable: instalar dependencias de `portable/package.json` en la raíz de una copia y ejecutar `npm run build`. El paquete raíz original corresponde al despliegue Sites. `portable/dist` contiene el cliente ya compilado.

## Monetización propuesta
Instalar una instancia por empresa de servicio y ofrecer configuración inicial, carga de equipos y soporte mensual. Los precios y contratos se definen comercialmente; esta aplicación no automatiza suscripciones ni cobros.
