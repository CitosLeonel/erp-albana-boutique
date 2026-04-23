-- ============================================================
--  ALBANA BOUTIQUE — Setup de Seguridad Completo
--  Ejecutá esto en: Supabase > SQL Editor > New query
--  ⚠️  Si ya ejecutaste el script anterior, ejecutá primero
--      el bloque "LIMPIEZA" del final para evitar conflictos.
-- ============================================================


-- ============================================================
--  1. TABLA DE PERFILES DE USUARIO
--     Vinculada a auth.users de Supabase (contraseñas bcrypt)
-- ============================================================
create table if not exists user_profiles (
  id      uuid primary key references auth.users(id) on delete cascade,
  name    text not null,
  role    text not null default 'vendedor' check (role in ('admin', 'vendedor')),
  email   text,
  created_at timestamptz default now()
);

-- Trigger: crear perfil automáticamente al registrar un usuario
create or replace function handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.user_profiles (id, name, role, email)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
    coalesce(new.raw_user_meta_data->>'role', 'vendedor'),
    new.email
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();


-- ============================================================
--  2. TABLAS OPERATIVAS
-- ============================================================
create table if not exists productos (
  id          uuid primary key default gen_random_uuid(),
  nombre      text not null,
  categoria   text not null default 'Otro',
  stock       integer not null default 0 check (stock >= 0),
  costo       numeric(12,2) not null default 0 check (costo >= 0),
  precio      numeric(12,2) not null default 0 check (precio >= 0),
  stock_min   integer not null default 3 check (stock_min >= 0),
  created_at  timestamptz default now()
);

create table if not exists clientes (
  id          uuid primary key default gen_random_uuid(),
  nombre      text not null,
  telefono    text,
  email       text,
  instagram   text,
  notas       text,
  created_at  timestamptz default now()
);

create table if not exists proveedores (
  id          uuid primary key default gen_random_uuid(),
  nombre      text not null,
  telefono    text,
  email       text,
  whatsapp    text,
  rubro       text,
  notas       text,
  created_at  timestamptz default now()
);

create table if not exists ventas (
  id          uuid primary key default gen_random_uuid(),
  fecha       date not null default current_date,
  producto_id uuid references productos(id) on delete set null,
  cliente_id  uuid references clientes(id) on delete set null,
  cant        integer not null default 1 check (cant > 0),
  precio      numeric(12,2) not null default 0 check (precio >= 0),
  pago        text not null default 'Efectivo',
  notas       text,
  vendedor    text,
  user_id     uuid references auth.users(id) on delete set null,
  created_at  timestamptz default now()
);

create table if not exists compras (
  id            uuid primary key default gen_random_uuid(),
  fecha         date not null default current_date,
  producto_id   uuid references productos(id) on delete set null,
  proveedor_id  uuid references proveedores(id) on delete set null,
  cant          integer not null default 1 check (cant > 0),
  costo         numeric(12,2) not null default 0 check (costo >= 0),
  notas         text,
  user_id       uuid references auth.users(id) on delete set null,
  created_at    timestamptz default now()
);

create table if not exists caja (
  id          uuid primary key default gen_random_uuid(),
  fecha       date not null default current_date,
  tipo        text not null check (tipo in ('ingreso', 'egreso')),
  descripcion text not null,
  monto       numeric(12,2) not null default 0 check (monto >= 0),
  categoria   text,
  user_id     uuid references auth.users(id) on delete set null,
  created_at  timestamptz default now()
);


-- ============================================================
--  3. ROW LEVEL SECURITY — Control de acceso REAL en servidor
--     Cada request es verificado por Supabase antes de ejecutar
-- ============================================================
alter table user_profiles enable row level security;
alter table productos      enable row level security;
alter table clientes       enable row level security;
alter table proveedores    enable row level security;
alter table ventas         enable row level security;
alter table compras        enable row level security;
alter table caja           enable row level security;

-- Helper: verificar si el usuario autenticado es admin
create or replace function is_admin()
returns boolean language sql security definer as $$
  select exists (
    select 1 from user_profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

-- Helper: verificar si el usuario está autenticado
create or replace function is_authenticated()
returns boolean language sql security definer as $$
  select auth.uid() is not null;
$$;


-- ── user_profiles ──────────────────────────────────────────
-- Cada usuario solo ve su propio perfil; admin ve todos
create policy "usuarios: ver propio perfil"
  on user_profiles for select
  using (id = auth.uid() or is_admin());

create policy "usuarios: admin actualiza perfiles"
  on user_profiles for update
  using (is_admin());

create policy "usuarios: admin borra perfiles"
  on user_profiles for delete
  using (is_admin());

-- ── productos ──────────────────────────────────────────────
create policy "productos: autenticados pueden ver"
  on productos for select
  using (is_authenticated());

create policy "productos: autenticados pueden insertar"
  on productos for insert
  with check (is_authenticated());

create policy "productos: autenticados pueden actualizar"
  on productos for update
  using (is_authenticated());

create policy "productos: solo admin puede borrar"
  on productos for delete
  using (is_admin());

-- ── clientes ───────────────────────────────────────────────
create policy "clientes: autenticados pueden ver"
  on clientes for select using (is_authenticated());

create policy "clientes: autenticados pueden insertar"
  on clientes for insert with check (is_authenticated());

create policy "clientes: autenticados pueden actualizar"
  on clientes for update using (is_authenticated());

create policy "clientes: solo admin puede borrar"
  on clientes for delete using (is_admin());

-- ── proveedores ────────────────────────────────────────────
create policy "proveedores: autenticados pueden ver"
  on proveedores for select using (is_authenticated());

create policy "proveedores: autenticados pueden insertar"
  on proveedores for insert with check (is_authenticated());

create policy "proveedores: autenticados pueden actualizar"
  on proveedores for update using (is_authenticated());

create policy "proveedores: solo admin puede borrar"
  on proveedores for delete using (is_admin());

-- ── ventas ─────────────────────────────────────────────────
create policy "ventas: autenticados pueden ver"
  on ventas for select using (is_authenticated());

create policy "ventas: autenticados pueden insertar"
  on ventas for insert with check (is_authenticated());

create policy "ventas: solo admin puede borrar"
  on ventas for delete using (is_admin());

-- ── compras ────────────────────────────────────────────────
create policy "compras: autenticados pueden ver"
  on compras for select using (is_authenticated());

create policy "compras: autenticados pueden insertar"
  on compras for insert with check (is_authenticated());

create policy "compras: solo admin puede borrar"
  on compras for delete using (is_admin());

-- ── caja ───────────────────────────────────────────────────
create policy "caja: autenticados pueden ver"
  on caja for select using (is_authenticated());

create policy "caja: autenticados pueden insertar"
  on caja for insert with check (is_authenticated());

create policy "caja: solo admin puede borrar"
  on caja for delete using (is_admin());


-- ============================================================
--  4. CONFIGURACIÓN DE AUTENTICACIÓN EN SUPABASE
--     (esto se configura en el dashboard, no via SQL)
--
--  Ir a: Authentication > Settings y configurar:
--
--  ✅ Minimum password length: 8
--  ✅ Require uppercase letters: ON
--  ✅ Require numbers: ON
--  ✅ Enable rate limiting: ON  (ya viene activado por defecto)
--  ✅ Max login attempts: 5  (ya viene por defecto)
--  ✅ Lockout duration: 5 minutes
--  ✅ Email confirmations: OFF (para uso interno sin email)
--
-- ============================================================


-- ============================================================
--  5. CREAR LOS 3 USUARIOS INICIALES
--     Ejecutá esto UNA SOLA VEZ para crear admin y vendedores
--     Supabase hashea las contraseñas con bcrypt automáticamente
-- ============================================================

-- ⚠️  IMPORTANTE: Cambiá estas contraseñas antes de usar en producción
-- Las contraseñas deben tener: mínimo 8 caracteres, 1 mayúscula, 1 número

-- Opción A: Crear desde el Dashboard
--   Authentication > Users > Add user
--   Email: admin@albanaboutique.com  Password: Admin2024!
--   Email: vendedor1@albanaboutique.com  Password: Vende2024!
--   Email: vendedor2@albanaboutique.com  Password: Vende2024!

-- Opción B: Crear via SQL (Supabase los hashea automáticamente)
do $$
declare
  admin_id   uuid;
  vendor1_id uuid;
  vendor2_id uuid;
begin
  -- Admin
  insert into auth.users (
    id, instance_id, email, encrypted_password, email_confirmed_at,
    raw_user_meta_data, created_at, updated_at, role, aud
  ) values (
    gen_random_uuid(), '00000000-0000-0000-0000-000000000000',
    'admin@albanaboutique.com',
    crypt('Admin2024!', gen_salt('bf')),
    now(),
    '{"name": "Administrador", "role": "admin"}'::jsonb,
    now(), now(), 'authenticated', 'authenticated'
  )
  on conflict (email) do nothing
  returning id into admin_id;

  -- Vendedor 1
  insert into auth.users (
    id, instance_id, email, encrypted_password, email_confirmed_at,
    raw_user_meta_data, created_at, updated_at, role, aud
  ) values (
    gen_random_uuid(), '00000000-0000-0000-0000-000000000000',
    'vendedor1@albanaboutique.com',
    crypt('Vende2024!', gen_salt('bf')),
    now(),
    '{"name": "Vendedor 1", "role": "vendedor"}'::jsonb,
    now(), now(), 'authenticated', 'authenticated'
  )
  on conflict (email) do nothing
  returning id into vendor1_id;

  -- Vendedor 2
  insert into auth.users (
    id, instance_id, email, encrypted_password, email_confirmed_at,
    raw_user_meta_data, created_at, updated_at, role, aud
  ) values (
    gen_random_uuid(), '00000000-0000-0000-0000-000000000000',
    'vendedor2@albanaboutique.com',
    crypt('Vende2024!', gen_salt('bf')),
    now(),
    '{"name": "Vendedor 2", "role": "vendedor"}'::jsonb,
    now(), now(), 'authenticated', 'authenticated'
  )
  on conflict (email) do nothing
  returning id into vendor2_id;

end $$;


-- ============================================================
--  6. DATOS DE EJEMPLO (opcional — borrá si no los querés)
-- ============================================================
insert into productos (nombre, categoria, stock, costo, precio, stock_min) values
  ('Remera Básica Blanca M', 'Remeras',    12, 2500,  5500, 3),
  ('Jean Slim Azul 38',      'Pantalones',  5, 8000, 18000, 2),
  ('Vestido Floral S',       'Vestidos',    2, 9000, 22000, 3),
  ('Campera Negra M',        'Camperas',    8,12000, 28000, 2),
  ('Remera Oversize L',      'Remeras',     1, 3000,  7000, 3)
on conflict do nothing;


-- ============================================================
--  LIMPIEZA (solo si necesitás resetear todo desde cero)
--  ⚠️  Esto BORRA TODOS LOS DATOS. Usá con cuidado.
-- ============================================================
/*
drop table if exists caja cascade;
drop table if exists compras cascade;
drop table if exists ventas cascade;
drop table if exists proveedores cascade;
drop table if exists clientes cascade;
drop table if exists productos cascade;
drop table if exists user_profiles cascade;
drop function if exists handle_new_user cascade;
drop function if exists is_admin cascade;
drop function if exists is_authenticated cascade;
*/
