-- ============================================================================
-- Sincronización de cfg entre dispositivos: hasta ahora vivía SOLO en
-- localStorage (switches de Inicio de Actividades/Facturación electrónica,
-- fechaInicioActividades, recordatorios propios y vencimientos marcados como
-- hechos), por lo que un dispositivo no veía lo que el otro configuraba.
--
-- Se separa en 3 tablas en vez de un solo blob JSON:
--   - config: 1 fila por org, solo los 3 switches/fecha (last-write-wins de
--     la fila completa, igual que cualquier gasto individual).
--   - hechos_venc: 1 fila por vencimiento marcado como hecho (la presencia
--     de la fila = hecho; togglear a "no hecho" borra la fila).
--   - recordatorios: 1 fila por recordatorio propio, mismo patrón que notas.
-- Las dos últimas usan merge por ítem (igual que gastos/notas) para que un
-- dispositivo con datos viejos NUNCA pueda borrar lo que el otro agregó.
--
-- Copia y pega TODO esto en Supabase SQL Editor (Settings → SQL Editor → New
-- query) y ejecútalo una sola vez. Es idempotente.
-- ============================================================================

-- 1) TABLA config -------------------------------------------------------------
create table if not exists public.config (
  org_id                    text primary key,
  inicio_actividades        boolean not null default false,
  fecha_inicio_actividades  date,
  facturacion_electronica   boolean not null default false,
  created_at                timestamptz not null default now(),
  updated_at                timestamptz not null default now()
);

create or replace function public.set_updated_at_config()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_config_updated_at on public.config;
create trigger trg_config_updated_at
  before update on public.config
  for each row
  execute function public.set_updated_at_config();

alter table public.config enable row level security;

drop policy if exists "jlp_org_rw" on public.config;
create policy "jlp_org_rw" on public.config
  for all
  to authenticated
  using (org_id = 'joylovepets-spa')
  with check (org_id = 'joylovepets-spa');

-- 2) TABLA hechos_venc ---------------------------------------------------------
create table if not exists public.hechos_venc (
  id         text primary key,
  org_id     text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.set_updated_at_hechos_venc()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_hechos_venc_updated_at on public.hechos_venc;
create trigger trg_hechos_venc_updated_at
  before update on public.hechos_venc
  for each row
  execute function public.set_updated_at_hechos_venc();

create index if not exists idx_hechos_venc_org_id on public.hechos_venc (org_id);

alter table public.hechos_venc enable row level security;

drop policy if exists "jlp_org_rw" on public.hechos_venc;
create policy "jlp_org_rw" on public.hechos_venc
  for all
  to authenticated
  using (org_id = 'joylovepets-spa')
  with check (org_id = 'joylovepets-spa');

-- 3) TABLA recordatorios --------------------------------------------------------
create table if not exists public.recordatorios (
  id         text primary key,
  org_id     text not null,
  titulo     text not null,
  vence      date not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.set_updated_at_recordatorios()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_recordatorios_updated_at on public.recordatorios;
create trigger trg_recordatorios_updated_at
  before update on public.recordatorios
  for each row
  execute function public.set_updated_at_recordatorios();

create index if not exists idx_recordatorios_org_id on public.recordatorios (org_id);

alter table public.recordatorios enable row level security;

drop policy if exists "jlp_org_rw" on public.recordatorios;
create policy "jlp_org_rw" on public.recordatorios
  for all
  to authenticated
  using (org_id = 'joylovepets-spa')
  with check (org_id = 'joylovepets-spa');

-- ============================================================================
-- VERIFICACIÓN
-- ============================================================================

-- Deben existir las 3 tablas con RLS habilitada.
select relname, relrowsecurity
from pg_class
where relname in ('config','hechos_venc','recordatorios')
  and relnamespace = 'public'::regnamespace::oid;

-- Debe verse "jlp_org_rw" con roles = {authenticated} (sin anon) en las 3.
select tablename, policyname, roles, cmd, qual
from pg_policies
where schemaname = 'public' and tablename in ('config','hechos_venc','recordatorios');
