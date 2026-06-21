# Guía: activar el cobro de forma segura (webhook de Tilopay)

## ¿Por qué?
Hoy la suscripción se "activa" desde el navegador leyendo la URL
(`?suscripcion=success&code=1&plan=anual`). Eso es **manipulable**: alguien podría
abrir esa URL a mano y activarse el plan **sin pagar**. La solución es que **solo
el servidor** active la suscripción, confirmando el pago con Tilopay.

Este repo ya incluye la pieza de servidor: `supabase/functions/tilopay-webhook/`.

---

## Lo que TÚ necesitas tener a mano
- Tu cuenta de **Tilopay** y sus credenciales de API (API key / usuario / clave).
- La **documentación del webhook de Tilopay** (cómo se llama cada campo que envían
  cuando un pago se aprueba). Esto es necesario para "ajustar" la función a su
  formato exacto (en el código está marcado con `// AJUSTAR`).
- **Supabase CLI** instalado (https://supabase.com/docs/guides/cli).

## Pasos
1. **Enlaza el proyecto** (una sola vez):
   ```bash
   supabase login
   supabase link --project-ref rxmyewcccqencycjqxpe
   ```

2. **Crea los secretos** (no van en el código):
   ```bash
   supabase secrets set TILOPAY_WEBHOOK_TOKEN=pon-aqui-algo-secreto-y-largo
   supabase secrets set TILOPAY_API_KEY=tu_api_key_de_tilopay
   # añade TILOPAY_API_USER / TILOPAY_API_PASSWORD si Tilopay los pide
   ```
   (`SUPABASE_URL` y `SUPABASE_SERVICE_ROLE_KEY` ya existen solos.)

3. **Despliega la función**:
   ```bash
   supabase functions deploy tilopay-webhook --no-verify-jwt
   ```

4. **Configura la URL del webhook en el panel de Tilopay**, apuntando a:
   ```
   https://rxmyewcccqencycjqxpe.functions.supabase.co/tilopay-webhook?token=EL-MISMO-TOKEN
   ```

5. **Ajusta los campos** en `supabase/functions/tilopay-webhook/index.ts` donde
   dice `// AJUSTAR`, según cómo Tilopay nombre los datos (código de aprobación,
   número de orden, identificador del usuario, plan). Vuelve a desplegar tras editar.

6. **Prueba** un pago real (o de sandbox) y confirma que la suscripción pasa a
   `activa` en la tabla `suscripciones`.

---

## Paso final (IMPORTANTE) — cerrar el hueco del navegador
Cuando el webhook ya funcione, hay que **quitarle al navegador el permiso de
cambiar su propia suscripción** (si no, el hueco sigue abierto). Corre entonces
`supabase/seguridad-suscripcion-servidor.sql` en el SQL Editor. **No lo corras
antes** de que el webhook funcione, o nadie podrá activarse al pagar.

> Mientras no actives todo esto, el botón de pago dentro de la app sigue diciendo
> "suscripción pronto disponible", así que el hueco no es explotable todavía en la
> práctica — pero conviene cerrarlo antes de activar el cobro.
