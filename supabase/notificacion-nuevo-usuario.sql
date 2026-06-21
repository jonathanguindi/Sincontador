-- =============================================================================
-- Notificación por correo cada vez que se registra un USUARIO NUEVO
-- =============================================================================
-- Qué hace: cada vez que alguien crea una cuenta en SinContador (se inserta una
-- fila en auth.users), Supabase envía automáticamente un correo de aviso al
-- administrador usando Resend (https://resend.com).
--
-- REQUISITOS (una sola vez):
--   1. Crea una cuenta gratis en https://resend.com
--   2. En Resend -> API Keys -> crea una API Key y cópiala (empieza con "re_...")
--   3. Reemplaza abajo:
--        - TU_RESEND_API_KEY  -> tu API key de Resend
--        - el correo de destino (ya está jonathanguindi12@gmail.com)
--   4. Pega TODO este archivo en Supabase -> SQL Editor -> Run
--
-- Nota: con el remitente "onboarding@resend.dev" Resend te permite enviarte
-- correos A TI MISMO (al correo dueño de la cuenta Resend) sin verificar dominio.
-- Si más adelante quieres enviar a otros correos o con tu propio dominio,
-- verifica un dominio en Resend y cambia el "from".
-- =============================================================================

-- 1) Habilitar la extensión que permite hacer llamadas HTTP desde la base de datos
create extension if not exists pg_net with schema extensions;

-- 2) Función que envía el correo cuando hay un usuario nuevo
create or replace function public.notificar_nuevo_usuario()
returns trigger
language plpgsql
security definer
set search_path = public, extensions, net
as $$
begin
  perform net.http_post(
    url     := 'https://api.resend.com/emails',
    headers := jsonb_build_object(
      'Content-Type',  'application/json',
      'Authorization', 'Bearer TU_RESEND_API_KEY'
    ),
    body    := jsonb_build_object(
      'from',    'SinContador <onboarding@resend.dev>',
      'to',      'jonathanguindi12@gmail.com',
      'subject', '🎉 Nuevo usuario en SinContador',
      'html',
        '<div style="font-family:Arial,sans-serif;font-size:15px;color:#102650">' ||
        '<h2>🎉 ¡Tienes un usuario nuevo!</h2>' ||
        '<p><b>Correo:</b> ' || coalesce(new.email, '—') || '</p>' ||
        '<p><b>Nombre:</b> ' || coalesce(new.raw_user_meta_data->>'nombre', '—') || '</p>' ||
        '<p><b>Fecha:</b> '  || to_char(now() at time zone 'America/Panama', 'YYYY-MM-DD HH24:MI') || ' (hora Panamá)</p>' ||
        '</div>'
    )
  );
  return new;
end;
$$;

-- 3) Disparador: se ejecuta automáticamente al crear cada usuario nuevo
drop trigger if exists on_nuevo_usuario_email on auth.users;
create trigger on_nuevo_usuario_email
  after insert on auth.users
  for each row execute function public.notificar_nuevo_usuario();
