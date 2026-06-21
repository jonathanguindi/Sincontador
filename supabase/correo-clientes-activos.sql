-- =============================================================================
-- Enviar por correo la LISTA de clientes activos (bajo demanda)
-- =============================================================================
-- Qué hace: te manda a tu correo la lista de clientes con acceso vigente
-- (suscripción activa de pago + pruebas vigentes), con nombre, correo y plan.
--
-- Úsalo cuando quieras: corre `select public.enviar_clientes_activos();`
-- (al final del archivo ya queda esa línea para que se envíe al pegarlo).
--
-- REQUISITOS: dominio sincontador.app verificado + reemplazar TU_RESEND_API_KEY.
-- =============================================================================

create extension if not exists pg_net with schema extensions;

create or replace function public.enviar_clientes_activos()
returns void
language plpgsql
security definer
set search_path = public, extensions, net
as $$
declare
  r       record;
  v_rows  text := '';
  v_count int := 0;
  v_html  text;
begin
  for r in
    select p.nombre, p.email, s.plan, s.estado, s.trial_fin, s.proximo_pago
    from public.suscripciones s
    join public.profiles p on p.id = s.user_id
    where s.estado = 'activa'
       or (s.plan = 'trial' and s.estado = 'trial'
           and (s.trial_fin is null or s.trial_fin > now()))
    order by (s.estado = 'activa') desc, p.nombre
  loop
    v_count := v_count + 1;
    v_rows := v_rows
      || '<tr>'
      || '<td style="padding:8px;border-bottom:1px solid #eee">' || coalesce(r.nombre, '—') || '</td>'
      || '<td style="padding:8px;border-bottom:1px solid #eee">' || coalesce(r.email, '—') || '</td>'
      || '<td style="padding:8px;border-bottom:1px solid #eee">'
      ||   case when r.estado = 'activa'
                then '💳 ' || coalesce(r.plan, 'pago')
                else '🎁 prueba' end
      || '</td></tr>';
  end loop;

  if v_count = 0 then
    v_rows := '<tr><td colspan="3" style="padding:12px;color:#6B7B92">Sin clientes activos por ahora.</td></tr>';
  end if;

  v_html :=
    '<div style="font-family:Arial,sans-serif;color:#102650">'
    || '<h2>👥 Clientes activos · SinContador (' || v_count || ')</h2>'
    || '<p style="font-size:13px;color:#6B7B92">' || to_char(now() at time zone 'America/Panama', 'DD/MM/YYYY HH24:MI') || ' (Panamá)</p>'
    || '<table style="width:100%;border-collapse:collapse;font-size:14px">'
    || '<tr><th align="left" style="padding:8px;border-bottom:2px solid #102650">Nombre</th>'
    || '<th align="left" style="padding:8px;border-bottom:2px solid #102650">Correo</th>'
    || '<th align="left" style="padding:8px;border-bottom:2px solid #102650">Plan</th></tr>'
    || v_rows
    || '</table></div>';

  perform net.http_post(
    url     := 'https://api.resend.com/emails',
    headers := jsonb_build_object(
      'Content-Type',  'application/json',
      'Authorization', 'Bearer TU_RESEND_API_KEY'
    ),
    body    := jsonb_build_object(
      'from',    'SinContador <avisos@sincontador.app>',
      'to',      'jonathang@jfkintl.com',
      'subject', '👥 Clientes activos · SinContador',
      'html',    v_html
    )
  );
end;
$$;

-- Enviarlo ahora:
select public.enviar_clientes_activos();

-- (Opcional) Para recibirlo automático cada lunes 8 a.m. Panamá, descomenta:
-- create extension if not exists pg_cron;
-- do $$ begin perform cron.unschedule('clientes-activos-semanal'); exception when others then null; end $$;
-- select cron.schedule('clientes-activos-semanal', '0 13 * * 1', $$ select public.enviar_clientes_activos(); $$);
