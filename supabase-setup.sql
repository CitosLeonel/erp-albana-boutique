-- ============================================================
--  ALBANA BOUTIQUE — Script SQL para Supabase
--  Ejecutá esto en: Supabase > SQL Editor > New query
-- ============================================================

-- 1. PRODUCTOS
create table if not exists productos (
  id          uuid primary key default gen_random_uuid(),
  nombre      text not null,
  categoria   text not null default 'Otro',
  stock       integer not null default 0,
  costo       numeric(12,2) not null default 0,
  precio      numeric(12,2) not null default 0,
  stock_min   integer not null default 3,
  created_at  timestamptz default now()
);

-- 2. CLIENTES
create table if not exists clientes (
  id          uuid primary key default gen_random_uuid(),
  nombre      text not null,
  telefono    text,
  email       text,
  instagram   text,
  notas       text,
  created_at  timestamptz default now()
);

-- 3. PROVEEDORES
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

-- 4. VENTAS
create table if not exists ventas (
  id          uuid primary key default gen_random_uuid(),
  fecha       date not null default current_date,
  producto_id uuid references productos(id) on delete set null,
  cliente_id  uuid references clientes(id) on delete set null,
  cant        integer not null default 1,
  precio      numeric(12,2) not null default 0,
  pago        text not null default 'Efectivo',
  notas       text,
  vendedor    text,
  created_at  timestamptz default now()
);

-- 5. COMPRAS
create table if not exists compras (
  id            uuid primary key default gen_random_uuid(),
  fecha         date not null default current_date,
  producto_id   uuid references productos(id) on delete set null,
  proveedor_id  uuid references proveedores(id) on delete set null,
  cant          integer not null default 1,
  costo         numeric(12,2) not null default 0,
  notas         text,
  created_at    timestamptz default now()
);

-- 6. CAJA (flujo de caja)
create table if not exists caja (
  id          uuid primary key default gen_random_uuid(),
  fecha       date not null default current_date,
  tipo        text not null check (tipo in ('ingreso', 'egreso')),
  descripcion text not null,
  monto       numeric(12,2) not null default 0,
  categoria   text,
  created_at  timestamptz default now()
);

-- ============================================================
--  SEGURIDAD: habilitar Row Level Security y permitir acceso
--  con la clave anon (anon key) — la app maneja el login propia
-- ============================================================
alter table productos  enable row level security;
alter table clientes   enable row level security;
alter table proveedores enable row level security;
alter table ventas     enable row level security;
alter table compras    enable row level security;
alter table caja       enable row level security;

-- Políticas: permitir todo con la anon key
-- (la seguridad real está en el login de la app)
create policy "allow_all_productos"   on productos   for all using (true) with check (true);
create policy "allow_all_clientes"    on clientes    for all using (true) with check (true);
create policy "allow_all_proveedores" on proveedores for all using (true) with check (true);
create policy "allow_all_ventas"      on ventas      for all using (true) with check (true);
create policy "allow_all_compras"     on compras     for all using (true) with check (true);
create policy "allow_all_caja"        on caja        for all using (true) with check (true);

-- ============================================================
--  DATOS DE EJEMPLO (opcional — podés borrar estas líneas)
-- ============================================================
insert into productos (nombre, categoria, stock, costo, precio, stock_min) values
  ('Remera Básica Blanca M',  'Remeras',    12, 2500,  5500,  3),
  ('Jean Slim Azul 38',       'Pantalones',  5, 8000, 18000,  2),
  ('Vestido Floral S',        'Vestidos',    2, 9000, 22000,  3),
  ('Campera Negra M',         'Camperas',    8,12000, 28000,  2),
  ('Remera Oversize L',       'Remeras',     1, 3000,  7000,  3);

insert into clientes (nombre, telefono, instagram, notas) values
  ('María González', '3512345678', '@mariag', 'Talle M'),
  ('Laura Pérez',    '3519876543', '@laup',   'Le gustan los jeans');

insert into proveedores (nombre, telefono, rubro, notas) values
  ('Textiles Norte', '3515551234', 'Remeras mayorista', 'Envío los jueves'),
  ('Jeans & Co.',    '3515559876', 'Pantalones denim',  '');
