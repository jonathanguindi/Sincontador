-- =============================================================================
-- CONFIGURACIÓN COMPLETA DE CORREOS · SinContador
-- =============================================================================
-- Pega TODO este archivo en Supabase -> SQL Editor, cambia la API key en el
-- ÚNICO lugar señalado abajo, y dale Run. Activa de una sola vez:
--   1) Correo de bienvenida al cliente que se registra
--   2) Aviso a ti cuando hay un usuario nuevo
--   3) Reporte diario de usuarios (8 a.m. Panamá)
--   4) Lista de clientes activos (bajo demanda)
--   5) Arreglo de seguridad para gestionar admins
--
-- ⚠️ Usa una API key NUEVA de Resend (la anterior quedó expuesta: bórrala y
--    crea una nueva en Resend -> API Keys).
-- =============================================================================

create extension if not exists pg_net with schema extensions;
create extension if not exists pg_cron;

-- ┌─────────────────────────────────────────────────────────────────────────┐
-- │  ÚNICO CAMBIO: pon aquí tu API key NUEVA de Resend (entre las comillas)   │
-- └─────────────────────────────────────────────────────────────────────────┘
create or replace function public.resend_key()
returns text language sql immutable
as $$ select 're_TU_CLAVE_NUEVA_DE_RESEND'::text $$;
-- ───────────────────────────────────────────────────────────────────────────


-- ════════════════════ 1) BIENVENIDA AL CLIENTE ════════════════════
create or replace function public.enviar_bienvenida_cliente()
returns trigger language plpgsql security definer
set search_path = public, extensions, net as $$
declare
  v_nombre text := coalesce(new.raw_user_meta_data->>'nombre','');
  v_saludo text := case when v_nombre='' then 'Hola' else 'Hola '||v_nombre end;
  v_html text;
begin
  if new.email is null then return new; end if;
  v_html :=
    '<div style="font-family:Arial,sans-serif;max-width:560px;margin:0 auto;background:#fff;border-radius:16px;overflow:hidden;border:1px solid #E0EDFB">'
    || '<div style="background:#102650;padding:28px;text-align:center"><div style="font-size:26px;font-weight:900;color:#fff">SIN <span style="color:#9ACDFC">CONTADOR</span></div><div style="font-size:12px;color:#9ACDFC;letter-spacing:.12em;margin-top:6px">LA CUENTA QUE SI CUADRA</div></div>'
    || '<div style="padding:32px"><h1 style="font-size:22px;color:#102650;margin:0 0 8px">'||v_saludo||', bienvenido a SinContador 🎉</h1>'
    || '<p style="font-size:15px;color:#4A5C75;line-height:1.6">Ya tienes todo listo para manejar el pago de tu empleada doméstica de forma legal y sin complicaciones, sin contratar un contador. Esto es lo que puedes hacer:</p>'
    || '<table style="width:100%;font-size:14px;color:#102650">'
    || '<tr><td style="padding:8px 0">🧾 <b>Recibos de pago legales</b> en PDF</td></tr>'
    || '<tr><td style="padding:8px 0">📅 <b>Décimo tercer mes</b> automático</td></tr>'
    || '<tr><td style="padding:8px 0">🏖️ <b>Vacaciones</b> proporcionales</td></tr>'
    || '<tr><td style="padding:8px 0">📄 <b>Liquidaciones y cartas legales</b></td></tr>'
    || '<tr><td style="padding:8px 0">💳 <b>Préstamos y adelantos</b></td></tr>'
    || '<tr><td style="padding:8px 0">🆔 <b>Escaneo de cédula</b></td></tr>'
    || '<tr><td style="padding:8px 0">📲 <b>Envío por WhatsApp</b></td></tr>'
    || '<tr><td style="padding:8px 0">⚖️ <b>Todo según la ley panameña</b></td></tr></table>'
    || '<div style="background:#EFF6FE;border:1px solid #BCDFFB;border-radius:12px;padding:16px;margin:22px 0;text-align:center;color:#1E40AF">🎁 <b>Tus primeros 30 días son gratis.</b> Sin tarjeta.</div>'
    || '<div style="text-align:center;margin:24px 0"><a href="https://sincontador.app/#/app" style="display:inline-block;background:#102650;color:#fff;text-decoration:none;font-weight:700;padding:14px 28px;border-radius:10px">Abrir SinContador →</a></div>'
    || '<p style="font-size:13px;color:#6B7B92;text-align:center">Si tienes dudas, escríbenos a soporte@sincontador.app.</p></div>'
    || '<div style="background:#F4F7FB;padding:18px;text-align:center;font-size:11px;color:#9ca3af">SinContador · Panamá</div></div>';
  perform net.http_post(
    url:='https://api.resend.com/emails',
    headers:=jsonb_build_object('Content-Type','application/json','Authorization','Bearer '||public.resend_key()),
    body:=jsonb_build_object('from','SinContador <hola@sincontador.app>','to',new.email,'subject','¡Bienvenido a SinContador! 🎉','html',v_html));
  return new;
end; $$;
drop trigger if exists on_nuevo_usuario_bienvenida on auth.users;
create trigger on_nuevo_usuario_bienvenida after insert on auth.users
  for each row execute function public.enviar_bienvenida_cliente();


-- ════════════════════ 2) AVISO A TI (usuario nuevo) ════════════════════
create or replace function public.notificar_nuevo_usuario()
returns trigger language plpgsql security definer
set search_path = public, extensions, net as $$
begin
  perform net.http_post(
    url:='https://api.resend.com/emails',
    headers:=jsonb_build_object('Content-Type','application/json','Authorization','Bearer '||public.resend_key()),
    body:=jsonb_build_object(
      'from','SinContador <avisos@sincontador.app>',
      'to','jonathang@jfkintl.com',
      'subject','🎉 Nuevo usuario en SinContador',
      'html','<h2>🎉 ¡Tienes un usuario nuevo!</h2><p><b>Correo:</b> '||coalesce(new.email,'—')
        ||'</p><p><b>Nombre:</b> '||coalesce(new.raw_user_meta_data->>'nombre','—')
        ||'</p><p><b>Fecha:</b> '||to_char(now() at time zone 'America/Panama','YYYY-MM-DD HH24:MI')||' (Panamá)</p>'));
  return new;
end; $$;
drop trigger if exists on_nuevo_usuario_email on auth.users;
create trigger on_nuevo_usuario_email after insert on auth.users
  for each row execute function public.notificar_nuevo_usuario();


-- ════════════════════ 3) REPORTE DIARIO ════════════════════
create or replace function public.reporte_diario_usuarios()
returns void language plpgsql security definer
set search_path = public, extensions, net, auth as $$
declare v_total int; v_activos int; v_trial int; v_vencidos int;
        v_nuevos_hoy int; v_login_hoy int; v_login_7d int; v_html text;
begin
  select count(*) into v_total from public.profiles;
  select count(*) into v_activos from public.suscripciones where estado='activa';
  select count(*) into v_trial from public.suscripciones where plan='trial' and estado='trial' and (trial_fin is null or trial_fin>now());
  select count(*) into v_vencidos from public.suscripciones where estado='expired' or (plan='trial' and trial_fin is not null and trial_fin<now());
  select count(*) into v_nuevos_hoy from public.profiles where created_at>=now()-interval '24 hours';
  select count(*) into v_login_hoy from auth.users where last_sign_in_at>=now()-interval '24 hours';
  select count(*) into v_login_7d from auth.users where last_sign_in_at>=now()-interval '7 days';
  v_html := '<div style="font-family:Arial,sans-serif;color:#102650"><h2>📊 Reporte diario · SinContador</h2>'
    ||'<table style="font-size:15px"><tr><td>👥 Usuarios totales</td><td style="text-align:right;font-weight:700;padding-left:24px">'||v_total||'</td></tr>'
    ||'<tr><td>💳 Suscripciones activas</td><td style="text-align:right;font-weight:700;padding-left:24px;color:#1E40AF">'||v_activos||'</td></tr>'
    ||'<tr><td>🎁 En prueba gratis</td><td style="text-align:right;font-weight:700;padding-left:24px">'||v_trial||'</td></tr>'
    ||'<tr><td>⏰ Vencidos</td><td style="text-align:right;font-weight:700;padding-left:24px;color:#B5451B">'||v_vencidos||'</td></tr>'
    ||'<tr><td>✨ Nuevos hoy</td><td style="text-align:right;font-weight:700;padding-left:24px;color:#16A34A">'||v_nuevos_hoy||'</td></tr>'
    ||'<tr><td>🔓 Iniciaron sesión hoy</td><td style="text-align:right;font-weight:700;padding-left:24px">'||v_login_hoy||'</td></tr>'
    ||'<tr><td>🗓️ Activos últimos 7 días</td><td style="text-align:right;font-weight:700;padding-left:24px">'||v_login_7d||'</td></tr></table></div>';
  perform net.http_post(
    url:='https://api.resend.com/emails',
    headers:=jsonb_build_object('Content-Type','application/json','Authorization','Bearer '||public.resend_key()),
    body:=jsonb_build_object('from','SinContador <avisos@sincontador.app>','to','jonathang@jfkintl.com','subject','📊 Reporte diario · SinContador','html',v_html));
end; $$;
do $$ begin perform cron.unschedule('reporte-diario-usuarios'); exception when others then null; end $$;
select cron.schedule('reporte-diario-usuarios','0 13 * * *',$$ select public.reporte_diario_usuarios(); $$);


-- ════════════════════ 4) LISTA DE CLIENTES ACTIVOS (bajo demanda) ════════════════════
create or replace function public.enviar_clientes_activos()
returns void language plpgsql security definer
set search_path = public, extensions, net as $$
declare r record; v_rows text:=''; v_count int:=0; v_html text;
begin
  for r in
    select p.nombre, p.email, s.plan, s.estado
    from public.suscripciones s join public.profiles p on p.id=s.user_id
    where s.estado='activa' or (s.plan='trial' and s.estado='trial' and (s.trial_fin is null or s.trial_fin>now()))
    order by (s.estado='activa') desc, p.nombre
  loop
    v_count:=v_count+1;
    v_rows:=v_rows||'<tr><td style="padding:8px;border-bottom:1px solid #eee">'||coalesce(r.nombre,'—')
      ||'</td><td style="padding:8px;border-bottom:1px solid #eee">'||coalesce(r.email,'—')
      ||'</td><td style="padding:8px;border-bottom:1px solid #eee">'||case when r.estado='activa' then '💳 '||coalesce(r.plan,'pago') else '🎁 prueba' end||'</td></tr>';
  end loop;
  if v_count=0 then v_rows:='<tr><td colspan="3" style="padding:12px">Sin clientes activos por ahora.</td></tr>'; end if;
  v_html:='<div style="font-family:Arial,sans-serif;color:#102650"><h2>👥 Clientes activos · SinContador ('||v_count||')</h2>'
    ||'<table style="width:100%;border-collapse:collapse;font-size:14px"><tr><th align="left" style="padding:8px;border-bottom:2px solid #102650">Nombre</th><th align="left" style="padding:8px;border-bottom:2px solid #102650">Correo</th><th align="left" style="padding:8px;border-bottom:2px solid #102650">Plan</th></tr>'||v_rows||'</table></div>';
  perform net.http_post(
    url:='https://api.resend.com/emails',
    headers:=jsonb_build_object('Content-Type','application/json','Authorization','Bearer '||public.resend_key()),
    body:=jsonb_build_object('from','SinContador <avisos@sincontador.app>','to','jonathang@jfkintl.com','subject','👥 Clientes activos · SinContador','html',v_html));
end; $$;


-- ════════════════════ 5) ARREGLO RLS: admin puede gestionar otros perfiles ════════════════════
-- (asegura que exista es_admin; si ya corriste seguridad-rls.sql, no pasa nada)
create or replace function public.es_admin()
returns boolean language sql security definer stable set search_path = public
as $$ select coalesce((select is_admin from public.profiles where id = auth.uid()), false); $$;

drop policy if exists "profiles_update_admin" on public.profiles;
create policy "profiles_update_admin" on public.profiles
  for update using ( public.es_admin() ) with check ( public.es_admin() );


-- ════════════════════ PRUEBAS (opcional) ════════════════════
-- Envíate la lista de clientes activos AHORA:
select public.enviar_clientes_activos();
-- Envíate el reporte diario AHORA (sin esperar):
-- select public.reporte_diario_usuarios();
