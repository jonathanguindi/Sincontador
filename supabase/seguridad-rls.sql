-- =============================================================================
-- SEGURIDAD: Row Level Security (RLS) para SinContador
-- =============================================================================
-- Qué hace: pone "reglas de acceso" en las tablas para que cada usuario solo
-- pueda ver y tocar SUS propios datos, y para que nadie pueda hacerse admin
-- a sí mismo desde el navegador. Cierra los riesgos C2 (auto-admin) y C3
-- (ver datos de otras familias/empleadas) de la auditoría.
--
-- CÓMO USARLO:
--   1. Abre Supabase -> SQL Editor:
--      https://supabase.com/dashboard/project/rxmyewcccqencycjqxpe/sql/new
--   2. Pega TODO este archivo y dale Run.
--   3. PRUEBA después: entra a la app con un usuario normal (que pueda ver sus
--      empleados y guardar pagos) y con tu usuario admin (que /admin cargue).
--
-- ⚠️ NOTA 1: Esto NO arregla por sí solo que alguien se "auto-active" el plan
--    pagado (riesgo C1). Eso requiere mover la activación al servidor con el
--    webhook de Tilopay. Mientras tanto, se deja que el usuario actualice su
--    propia suscripción para no romper el flujo actual de pago.
-- ⚠️ NOTA 2: Si algo se rompe, al final está cómo desactivar RLS temporalmente.
-- =============================================================================


-- 0) DIAGNÓSTICO (opcional, solo lectura): ver si RLS ya está activado
-- -----------------------------------------------------------------------------
select tablename, rowsecurity as rls_activado
from pg_tables
where schemaname = 'public'
  and tablename in ('profiles','suscripciones','user_data');


-- 1) Función auxiliar: ¿el usuario actual es admin?
--    SECURITY DEFINER => puede leer profiles sin chocar con las políticas (evita recursión).
-- -----------------------------------------------------------------------------
create or replace function public.es_admin()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select coalesce((select is_admin from public.profiles where id = auth.uid()), false);
$$;


-- 2) PROFILES (perfil de cada usuario) ----------------------------------------
alter table public.profiles enable row level security;

-- Leer: solo tu propio perfil; el admin puede leer todos
drop policy if exists "profiles_select" on public.profiles;
create policy "profiles_select" on public.profiles
  for select using ( id = auth.uid() or public.es_admin() );

-- Crear: solo tu propio perfil (por si la app lo inserta)
drop policy if exists "profiles_insert" on public.profiles;
create policy "profiles_insert" on public.profiles
  for insert with check ( id = auth.uid() );

-- Actualizar: solo tu propio perfil
drop policy if exists "profiles_update" on public.profiles;
create policy "profiles_update" on public.profiles
  for update using ( id = auth.uid() ) with check ( id = auth.uid() );

-- Evitar que un usuario se ponga is_admin = true a sí mismo desde el navegador.
-- (Un admin promoviendo a OTRO, o tú desde el SQL Editor, sí pueden.)
create or replace function public.bloquear_autoascenso_admin()
returns trigger
language plpgsql
security definer
as $$
begin
  if new.is_admin is distinct from old.is_admin and auth.uid() = new.id then
    new.is_admin := old.is_admin;  -- ignora el cambio
  end if;
  return new;
end;
$$;

drop trigger if exists trg_bloquear_autoascenso_admin on public.profiles;
create trigger trg_bloquear_autoascenso_admin
  before update on public.profiles
  for each row execute function public.bloquear_autoascenso_admin();


-- 3) SUSCRIPCIONES ------------------------------------------------------------
alter table public.suscripciones enable row level security;

drop policy if exists "suscripciones_select" on public.suscripciones;
create policy "suscripciones_select" on public.suscripciones
  for select using ( user_id = auth.uid() or public.es_admin() );

drop policy if exists "suscripciones_insert" on public.suscripciones;
create policy "suscripciones_insert" on public.suscripciones
  for insert with check ( user_id = auth.uid() );

-- Se permite actualizar la propia para NO romper el flujo de pago actual.
-- (Cuando exista el webhook de Tilopay, conviene quitar esta política.)
drop policy if exists "suscripciones_update" on public.suscripciones;
create policy "suscripciones_update" on public.suscripciones
  for update using ( user_id = auth.uid() ) with check ( user_id = auth.uid() );


-- 4) USER_DATA (lo más sensible: empleadas, pagos, préstamos, gastos) ---------
alter table public.user_data enable row level security;

-- Leer: solo lo tuyo; el admin puede leer (para el panel "ver usuario")
drop policy if exists "user_data_select" on public.user_data;
create policy "user_data_select" on public.user_data
  for select using ( user_id = auth.uid() or public.es_admin() );

-- Escribir/actualizar/borrar: SOLO el dueño
drop policy if exists "user_data_insert" on public.user_data;
create policy "user_data_insert" on public.user_data
  for insert with check ( user_id = auth.uid() );

drop policy if exists "user_data_update" on public.user_data;
create policy "user_data_update" on public.user_data
  for update using ( user_id = auth.uid() ) with check ( user_id = auth.uid() );

drop policy if exists "user_data_delete" on public.user_data;
create policy "user_data_delete" on public.user_data
  for delete using ( user_id = auth.uid() );


-- =============================================================================
-- REVERSA DE EMERGENCIA (solo si algo se rompe tras aplicar lo de arriba)
-- Descomenta y corre estas líneas para desactivar RLS temporalmente:
--
-- alter table public.profiles      disable row level security;
-- alter table public.suscripciones disable row level security;
-- alter table public.user_data     disable row level security;
-- =============================================================================
