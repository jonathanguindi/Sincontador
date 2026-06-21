-- =============================================================================
-- Correo de BIENVENIDA al cliente que se registra
-- =============================================================================
-- Qué hace: cada vez que alguien crea una cuenta, le llega a SU correo un email
-- de bienvenida explicando qué es SinContador y todo lo que puede hacer.
-- (Esto es distinto del aviso que te llega A TI cuando hay un usuario nuevo.)
--
-- REQUISITOS:
--   - Dominio sincontador.app verificado en Resend (ya lo tienes).
--   - Reemplaza TU_RESEND_API_KEY por tu clave de Resend.
--   - Pega TODO en Supabase -> SQL Editor -> Run.
-- =============================================================================

create extension if not exists pg_net with schema extensions;

create or replace function public.enviar_bienvenida_cliente()
returns trigger
language plpgsql
security definer
set search_path = public, extensions, net
as $$
declare
  v_nombre text := coalesce(new.raw_user_meta_data->>'nombre', '');
  v_saludo text := case when v_nombre = '' then 'Hola' else 'Hola ' || v_nombre end;
  v_html   text;
begin
  v_html :=
  '<div style="font-family:Arial,Helvetica,sans-serif;max-width:560px;margin:0 auto;background:#ffffff;border-radius:16px;overflow:hidden;border:1px solid #E0EDFB">'
  || '<div style="background:#102650;padding:28px 32px;text-align:center">'
  ||   '<div style="font-size:26px;font-weight:900;letter-spacing:.04em;color:#fff">SIN <span style="color:#9ACDFC">CONTADOR</span></div>'
  ||   '<div style="font-size:12px;color:#9ACDFC;letter-spacing:.12em;margin-top:6px">LA CUENTA QUE SI CUADRA</div>'
  || '</div>'
  || '<div style="padding:32px">'
  ||   '<h1 style="font-size:22px;color:#102650;margin:0 0 8px">' || v_saludo || ', bienvenido a SinContador 🎉</h1>'
  ||   '<p style="font-size:15px;color:#4A5C75;line-height:1.6;margin:0 0 20px">'
  ||     'Ya tienes todo listo para manejar el pago de tu empleada doméstica de forma legal y sin complicaciones, '
  ||     'sin necesidad de contratar un contador. Esto es lo que puedes hacer:'
  ||   '</p>'
  ||   '<table style="width:100%;font-size:14px;color:#102650;border-collapse:collapse">'
  ||     '<tr><td style="padding:8px 0">🧾 <b>Recibos de pago legales</b> en PDF (quincena, horas extra, deducciones)</td></tr>'
  ||     '<tr><td style="padding:8px 0">📅 <b>Décimo tercer mes</b> calculado automáticamente</td></tr>'
  ||     '<tr><td style="padding:8px 0">🏖️ <b>Vacaciones</b> proporcionales al día</td></tr>'
  ||     '<tr><td style="padding:8px 0">📄 <b>Liquidaciones y cartas legales</b> (despido, mutuo acuerdo, finiquito)</td></tr>'
  ||     '<tr><td style="padding:8px 0">💳 <b>Préstamos y adelantos</b> con control de saldo</td></tr>'
  ||     '<tr><td style="padding:8px 0">🆔 <b>Escaneo de cédula</b> para registrar rápido</td></tr>'
  ||     '<tr><td style="padding:8px 0">📲 <b>Envío por WhatsApp</b> de los recibos</td></tr>'
  ||     '<tr><td style="padding:8px 0">⚖️ <b>Todo según la ley panameña</b> (Decreto 13, CSS Ley 462, Código de Trabajo)</td></tr>'
  ||   '</table>'
  ||   '<div style="background:#EFF6FE;border:1px solid #BCDFFB;border-radius:12px;padding:16px;margin:22px 0;text-align:center;font-size:14px;color:#1E40AF">'
  ||     '🎁 <b>Tus primeros 30 días son gratis.</b> Sin tarjeta de crédito.'
  ||   '</div>'
  ||   '<div style="text-align:center;margin:24px 0 8px">'
  ||     '<a href="https://sincontador.app/#/app" style="display:inline-block;background:#102650;color:#fff;text-decoration:none;'
  ||       'font-size:15px;font-weight:700;padding:14px 28px;border-radius:10px">Abrir SinContador →</a>'
  ||   '</div>'
  ||   '<p style="font-size:13px;color:#6B7B92;line-height:1.6;text-align:center;margin:20px 0 0">'
  ||     'Si tienes dudas, escríbenos a soporte@sincontador.app. Estamos para ayudarte.'
  ||   '</p>'
  || '</div>'
  || '<div style="background:#F4F7FB;padding:18px;text-align:center;font-size:11px;color:#9ca3af">'
  ||   'SinContador · Panamá · La cuenta que sí cuadra'
  || '</div>'
  || '</div>';

  perform net.http_post(
    url     := 'https://api.resend.com/emails',
    headers := jsonb_build_object(
      'Content-Type',  'application/json',
      'Authorization', 'Bearer TU_RESEND_API_KEY'
    ),
    body    := jsonb_build_object(
      'from',    'SinContador <hola@sincontador.app>',
      'to',      new.email,
      'subject', '¡Bienvenido a SinContador! 🎉',
      'html',    v_html
    )
  );
  return new;
end;
$$;

drop trigger if exists on_nuevo_usuario_bienvenida on auth.users;
create trigger on_nuevo_usuario_bienvenida
  after insert on auth.users
  for each row execute function public.enviar_bienvenida_cliente();
