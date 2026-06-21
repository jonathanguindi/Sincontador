-- =============================================================================
-- Reporte DIARIO de usuarios por correo
-- =============================================================================
-- Qué hace: cada día, a la hora que elijas, te envía un correo con un resumen
-- de tus usuarios (total, activos de pago, en prueba, vencidos, nuevos del día
-- y cuántos iniciaron sesión). Usa Resend (igual que la notificación de usuario
-- nuevo) y pg_cron para programarlo.
--
-- REQUISITOS:
--   - Ya debes tener tu API key de Resend (la misma que usas para los avisos).
--   - Reemplaza abajo TU_RESEND_API_KEY por tu clave.
--   - Pega TODO en Supabase -> SQL Editor -> Run.
--
-- HORA: está programado para las 13:00 UTC = 8:00 a.m. en Panamá.
--   Para cambiarla, ajusta el '0 13 * * *' (formato cron, en UTC). Ej:
--   '0 12 * * *' = 7:00 a.m. Panamá ; '0 22 * * *' = 5:00 p.m. Panamá.
-- =============================================================================

create extension if not exists pg_cron;
create extension if not exists pg_net with schema extensions;

create or replace function public.reporte_diario_usuarios()
returns void
language plpgsql
security definer
set search_path = public, extensions, net, auth
as $$
declare
  v_total        int;
  v_activos      int;
  v_trial        int;
  v_vencidos     int;
  v_nuevos_hoy   int;
  v_login_hoy    int;
  v_login_7d     int;
  v_html         text;
begin
  select count(*) into v_total from public.profiles;

  select count(*) into v_activos
    from public.suscripciones where estado = 'activa';

  select count(*) into v_trial
    from public.suscripciones
    where plan = 'trial' and estado = 'trial'
      and (trial_fin is null or trial_fin > now());

  select count(*) into v_vencidos
    from public.suscripciones
    where estado = 'expired'
       or (plan = 'trial' and trial_fin is not null and trial_fin < now());

  select count(*) into v_nuevos_hoy
    from public.profiles where created_at >= now() - interval '24 hours';

  select count(*) into v_login_hoy
    from auth.users where last_sign_in_at >= now() - interval '24 hours';

  select count(*) into v_login_7d
    from auth.users where last_sign_in_at >= now() - interval '7 days';

  v_html :=
    '<div style="font-family:Arial,sans-serif;color:#102650;max-width:520px">' ||
    '<h2 style="color:#102650">📊 Reporte diario · SinContador</h2>' ||
    '<p style="color:#6B7B92;font-size:13px">' ||
       to_char(now() at time zone 'America/Panama', 'DD/MM/YYYY') || ' (hora Panamá)</p>' ||
    '<table style="width:100%;border-collapse:collapse;font-size:15px">' ||
    '<tr><td style="padding:10px;border-bottom:1px solid #eee">👥 Usuarios totales</td>' ||
        '<td style="padding:10px;border-bottom:1px solid #eee;text-align:right;font-weight:700">' || v_total || '</td></tr>' ||
    '<tr><td style="padding:10px;border-bottom:1px solid #eee">💳 Suscripciones activas (pago)</td>' ||
        '<td style="padding:10px;border-bottom:1px solid #eee;text-align:right;font-weight:700;color:#1E40AF">' || v_activos || '</td></tr>' ||
    '<tr><td style="padding:10px;border-bottom:1px solid #eee">🎁 En prueba gratis</td>' ||
        '<td style="padding:10px;border-bottom:1px solid #eee;text-align:right;font-weight:700">' || v_trial || '</td></tr>' ||
    '<tr><td style="padding:10px;border-bottom:1px solid #eee">⏰ Vencidos</td>' ||
        '<td style="padding:10px;border-bottom:1px solid #eee;text-align:right;font-weight:700;color:#B5451B">' || v_vencidos || '</td></tr>' ||
    '<tr><td style="padding:10px;border-bottom:1px solid #eee">✨ Nuevos hoy (24h)</td>' ||
        '<td style="padding:10px;border-bottom:1px solid #eee;text-align:right;font-weight:700;color:#16A34A">' || v_nuevos_hoy || '</td></tr>' ||
    '<tr><td style="padding:10px;border-bottom:1px solid #eee">🔓 Iniciaron sesión hoy</td>' ||
        '<td style="padding:10px;border-bottom:1px solid #eee;text-align:right;font-weight:700">' || v_login_hoy || '</td></tr>' ||
    '<tr><td style="padding:10px">🗓️ Activos últimos 7 días</td>' ||
        '<td style="padding:10px;text-align:right;font-weight:700">' || v_login_7d || '</td></tr>' ||
    '</table></div>';

  perform net.http_post(
    url     := 'https://api.resend.com/emails',
    headers := jsonb_build_object(
      'Content-Type',  'application/json',
      'Authorization', 'Bearer TU_RESEND_API_KEY'
    ),
    body    := jsonb_build_object(
      'from',    'SinContador <onboarding@resend.dev>',
      'to',      'jonathanguindi12@gmail.com',
      'subject', '📊 Reporte diario · SinContador',
      'html',    v_html
    )
  );
end;
$$;

-- Programar el envío diario (evita duplicar el job si ya existía)
do $$
begin
  perform cron.unschedule('reporte-diario-usuarios');
exception when others then null;
end $$;

select cron.schedule(
  'reporte-diario-usuarios',
  '0 13 * * *',                                  -- 13:00 UTC = 8:00 a.m. Panamá
  $$ select public.reporte_diario_usuarios(); $$
);

-- (Opcional) Para probarlo YA mismo sin esperar al día siguiente, corre:
--   select public.reporte_diario_usuarios();
