-- ============================================================================
-- Tabla productos: inventario con costo unitario, para poder calcular el
-- margen real de cada venta en `ingresos` (hoy solo registra precio de
-- venta, no costo). Mismo estilo que liquidaciones/reembolsos: id text
-- generado en el cliente con uid(), NO serial.
--
-- Copia y pega TODO esto en Supabase SQL Editor (Settings → SQL Editor → New
-- query) y ejecútalo una sola vez. Es idempotente.
-- ============================================================================

-- 1) TABLA -------------------------------------------------------------------
create table if not exists public.productos (
  id             text primary key,
  org_id         text not null,
  sku            text,
  nombre         text not null,
  marca          text not null check (marca in ('JoyLovePets','Jevima','Común')),
  categoria      text,
  talla          text,
  costo_unitario numeric not null default 0,
  stock_actual   integer not null default 0,
  stock_inicial  integer not null default 0,
  activo         boolean not null default true,
  autor          text references public.usuarios(id),
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

-- Trigger para mantener updated_at al día (usado por el merge last-write-wins
-- del cliente, igual que en gastos/notas/eventos/ingresos/reembolsos/liquidaciones/archivos).
create or replace function public.set_updated_at_productos()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_productos_updated_at on public.productos;
create trigger trg_productos_updated_at
  before update on public.productos
  for each row
  execute function public.set_updated_at_productos();

create index if not exists idx_productos_org_id on public.productos (org_id);

-- 2) RLS -----------------------------------------------------------------
-- SOLO "authenticated" — mismo cierre que el resto de las tablas desde
-- close_rls_authenticated_only.sql. No se reabre acceso anon.
alter table public.productos enable row level security;

drop policy if exists "jlp_org_rw" on public.productos;
create policy "jlp_org_rw" on public.productos
  for all
  to authenticated
  using (org_id = 'joylovepets-spa')
  with check (org_id = 'joylovepets-spa');

-- ============================================================================
-- VERIFICACIÓN
-- ============================================================================

-- Debe existir la tabla con RLS habilitada.
select relname, relrowsecurity
from pg_class
where relname = 'productos' and relnamespace = 'public'::regnamespace::oid;

-- Debe verse "jlp_org_rw" con roles = {authenticated} (sin anon).
select tablename, policyname, roles, cmd, qual
from pg_policies
where schemaname = 'public' and tablename = 'productos';
