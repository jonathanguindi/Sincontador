-- =============================================================================
-- Cerrar el hueco C1: que el navegador NO pueda activar suscripciones
-- =============================================================================
-- ⚠️ CORRE ESTO SOLO DESPUÉS de que el webhook de Tilopay esté funcionando
--    (ver supabase/GUIA-TILOPAY.md). Si lo corres antes, al pagar nadie podrá
--    activarse, porque la activación pasará a ser exclusiva del servidor.
--
-- Qué hace: elimina el permiso de UPDATE del usuario sobre su suscripción.
-- A partir de aquí, SOLO la service role (el webhook) puede cambiar estado/plan.
-- El usuario sigue pudiendo LEER su suscripción y CREAR su trial (insert).
-- =============================================================================

-- Quitar el permiso de actualizar la propia suscripción desde el cliente
drop policy if exists "suscripciones_update" on public.suscripciones;

-- (Opcional) Si quieres que el trial tampoco se cree desde el cliente sino
-- mediante un trigger/servidor, también podrías quitar el insert:
-- drop policy if exists "suscripciones_insert" on public.suscripciones;

-- Nota: la service role (usada por la Edge Function tilopay-webhook) ignora RLS,
-- así que el webhook seguirá pudiendo activar la suscripción sin problema.
