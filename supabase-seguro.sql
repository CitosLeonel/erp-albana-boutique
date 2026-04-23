-- ============================================================
--  ALBANA BOUTIQUE — Setup completo (versión corregida)
--  Ejecutá esto en: Supabase > SQL Editor > New query
-- ============================================================

-- ── TABLAS ───────────────────────────────────────────────────
create table if not exists user_profiles (
  id         uuid primary key references auth.users(id) on delete cascade,
  name       text not null,
  role       text not null default 'vendedor' check (role in ('admin', 'vendedor')),
  email      text,
  created_at timestamptz default now()
);

create table if not exists productos (
  id         uuid primary key default gen_random_uuid(),
  nombre     text not null,
  categoria  text not null default 'Otro',
  stock      integer not null default 0 check (stock >= 0),
  costo      numeric(12,2) not null default 0,
  precio     numeric(12,2) not null default 0,
  stock_min  integer not null default 3,
  created_at timestamptz default now()
);

create table if not exists clientes (
  id         uuid primary key default gen_random_uuid(),
  nombre     text not null,
  telefono   text, email text, instagram text, notas text,
  created_at timestamptz default now()
);

create table if not exists proveedores (
  id         uuid primary key default gen_random_uuid(),
  nombre     text not null,
  telefono   text, email text, whatsapp text, rubro text, notas text,
  created_at timestamptz default now()
);

create table if not exists ventas (
  id          uuid primary key default gen_random_uuid(),
  fecha       date not null default current_date,
  producto_id uuid references productos(id) on delete set null,
  cliente_id  uuid references clientes(id) on delete set null,
  cant        integer not null default 1 check (cant > 0),
  precio      numeric(12,2) not null default 0,
  pago        text not null default 'Efectivo',
  notas       text, vendedor text,
  user_id     uuid references auth.users(id) on delete set null,
  created_at  timestamptz default now()
);

create table if not exists compras (
  id           uuid primary key default gen_random_uuid(),
  fecha        date not null default current_date,
  producto_id  uuid references productos(id) on delete set null,
  proveedor_id uuid references proveedores(id) on delete set null,
  cant         integer not null default 1 check (cant > 0),
  costo        numeric(12,2) not null default 0,
  notas        text,
  user_id      uuid references auth.users(id) on delete set null,
  created_at   timestamptz default now()
);

create table if not exists caja (
  id          uuid primary key default gen_random_uuid(),
  fecha       date not null default current_date,
  tipo        text not null check (tipo in ('ingreso', 'egreso')),
  descripcion text not null,
  monto       numeric(12,2) not null default 0,
  categoria   text,
  user_id     uuid references auth.users(id) on delete set null,
  created_at  timestamptz default now()
);

-- ── TRIGGER: crear perfil al registrar usuario ───────────────
create or replace function handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.user_profiles (id, name, role, email)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
    coalesce(new.raw_user_meta_data->>'role', 'vendedor'),
    new.email
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

-- ── HELPER para RLS ──────────────────────────────────────────
create or replace function is_admin()
returns boolean language sql security definer as $$
  select exists (
    select 1 from user_profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

-- ── ROW LEVEL SECURITY ───────────────────────────────────────
alter table user_profiles enable row level security;
alter table productos      enable row level security;
alter table clientes       enable row level security;
alter table proveedores    enable row level security;
alter table ventas         enable row level security;
alter table compras        enable row level security;
alter table caja           enable row level security;

-- Limpiar políticas viejas
do $$ declare r record; begin
  for r in select policyname, tablename from pg_policies
    where schemaname = 'public'
    and tablename in ('user_profiles','productos','clientes','proveedores','ventas','compras','caja')
  loop
    execute format('drop policy if exists %I on %I', r.policyname, r.tablename);
  end loop;
end $$;

-- user_profiles
create policy "up_select" on user_profiles for select
  using (id = auth.uid() or is_admin());
create policy "up_insert" on user_profiles for insert
  with check (true);
create policy "up_update" on user_profiles for update
  using (is_admin());
create policy "up_delete" on user_profiles for delete
  using (is_admin());

-- productos
create policy "prod_s" on productos for select using (auth.uid() is not null);
create policy "prod_i" on productos for insert with check (auth.uid() is not null);
create policy "prod_u" on productos for update using (auth.uid() is not null);
create policy "prod_d" on productos for delete using (is_admin());

-- clientes
create policy "cli_s" on clientes for select using (auth.uid() is not null);
create policy "cli_i" on clientes for insert with check (auth.uid() is not null);
create policy "cli_u" on clientes for update using (auth.uid() is not null);
create policy "cli_d" on clientes for delete using (is_admin());

-- proveedores
create policy "prov_s" on proveedores for select using (auth.uid() is not null);
create policy "prov_i" on proveedores for insert with check (auth.uid() is not null);
create policy "prov_u" on proveedores for update using (auth.uid() is not null);
create policy "prov_d" on proveedores for delete using (is_admin());

-- ventas
create policy "ven_s" on ventas for select using (auth.uid() is not null);
create policy "ven_i" on ventas for insert with check (auth.uid() is not null);
create policy "ven_d" on ventas for delete using (is_admin());

-- compras
create policy "comp_s" on compras for select using (auth.uid() is not null);
create policy "comp_i" on compras for insert with check (auth.uid() is not null);
create policy "comp_d" on compras for delete using (is_admin());

-- caja
create policy "caja_s" on caja for select using (auth.uid() is not null);
create policy "caja_i" on caja for insert with check (auth.uid() is not null);
create policy "caja_d" on caja for delete using (is_admin());

-- ── DATOS DE EJEMPLO (opcional) ──────────────────────────────
insert into productos (nombre, categoria, stock, costo, precio, stock_min) values
  ('Remera Básica Blanca M', 'Remeras',    12, 2500,  5500, 3),
  ('Jean Slim Azul 38',      'Pantalones',  5, 8000, 18000, 2),
  ('Vestido Floral S',       'Vestidos',    2, 9000, 22000, 3),
  ('Campera Negra M',        'Camperas',    8,12000, 28000, 2),
  ('Remera Oversize L',      'Remeras',     1, 3000,  7000, 3)
on conflict do nothing;

-- ============================================================
--  ✅ SQL ejecutado correctamente.
--
--  SIGUIENTE PASO — Crear los 3 usuarios desde el Dashboard:
--
--  Supabase → Authentication → Users → "Add user" (botón)
--
--  1. Email: admin@albanaboutique.com
--     Password: Admin2024!
--     ✓ tildar "Auto Confirm User"
--     → Después ir a Table Editor → user_profiles
--       y cambiar su "role" a "admin"
--
--  2. Email: vendedor1@albanaboutique.com
--     Password: Vende2024!
--     ✓ tildar "Auto Confirm User"
--     (role queda en "vendedor" automáticamente)
--
--  3. Email: vendedor2@albanaboutique.com
--     Password: Vende2024!
--     ✓ tildar "Auto Confirm User"
--
--  Después cambiá las contraseñas desde el mismo panel
--  antes de darlas a las vendedoras.
-- ============================================================