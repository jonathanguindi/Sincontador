-- ============================================================================
--  ELIMINAR CUENTA  ·  SinContador
--  Requisito de Apple (Guideline 5.1.1(v)): toda app que permite crear cuenta
--  debe permitir tambien ELIMINARLA desde la propia app.
--
--  Esta funcion permite que un usuario borre SU PROPIA cuenta y todos sus
--  datos. La app la llama con:  supabase.rpc('delete_user')
--
--  COMO USARLA:
--  1. Entra a tu proyecto en Supabase -> SQL Editor.
--  2. Pega TODO este archivo y dale "Run".
--  3. Debe decir "Success. No rows returned" (eso es normal).
-- ============================================================================

create or replace function public.delete_user()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
begin
  -- Seguridad: solo el usuario autenticado puede borrarse a si mismo.
  if uid is null then
    raise exception 'No autenticado';
  end if;

  -- Borrar todos los datos del usuario.
  delete from public.user_data    where user_id = uid;
  delete from public.suscripciones where user_id = uid;
  delete from public.profiles      where id = uid;

  -- Borrar la cuenta de autenticacion (esto cierra la sesion y elimina el login).
  delete from auth.users where id = uid;
end;
$$;

-- Permitir que cualquier usuario autenticado pueda ejecutar la funcion
-- (solo puede borrarse a si mismo, por el auth.uid() de adentro).
grant execute on function public.delete_user() to authenticated;
