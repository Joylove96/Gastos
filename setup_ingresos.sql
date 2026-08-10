-- ============================================================================
-- Módulo de INGRESOS (ventas). Prerequisito de Flujo de Caja y Runway: hoy la
-- app solo registra egresos (gastos), así que no puede mostrar margen real.
-- Mismo estilo que "archivos" (setup_sync_archivos.sql): id text generado en
-- el cliente con uid(), NO serial. autor -> usuarios.id (FK real, igual que
-- gastos/notas/eventos — ver seed_usuarios.sql sobre por qué esa FK importa).
--
-- Copia y pega TODO esto en Supabase SQL Editor (Settings → SQL Editor → New
-- query) y ejecútalo una sola vez. Es idempotente.
-- ============================================================================

-- 1) TABLA -------------------------------------------------------------------
create table if not exists public.ingresos (
  id               text primary key,
  org_id           text not null,
  fecha            date not null,
  canal            text not null check (canal in ('Mercado Libre','Falabella','Directo','B2B','Otro')),
  marca            text not null check (marca in ('JoyLovePets','Jevima','Común')),
  descripcion      text,
  cantidad         int not null default 1,
  precio_unitario  numeric not null default 0,
  monto_bruto      numeric not null default 0,
  comision_monto   numeric not null default 0,
  costo_envio      numeric not null default 0,
  monto_neto       numeric not null default 0,
  tipo_documento   text not null check (tipo_documento in ('Boleta','Factura','Sin documento')),
  iva_debito       numeric not null default 0,
  estado           text not null default 'Recibido' check (estado in ('Pendiente','Recibido')),
  autor            text references public.usuarios(id),
  notas            text,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

-- Trigger para mantener updated_at al día (usado por el merge last-write-wins
-- del cliente, igual que en gastos/notas/eventos/archivos).
create or replace function public.set_updated_at_ingresos()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_ingresos_updated_at on public.ingresos;
create trigger trg_ingresos_updated_at
  before update on public.ingresos
  for each row
  execute function public.set_updated_at_ingresos();

create index if not exists idx_ingresos_org_id on public.ingresos (org_id);
create index if not exists idx_ingresos_fecha on public.ingresos (fecha);

-- 2) RLS -----------------------------------------------------------------
-- SOLO "authenticated" — el acceso anon ya se cerró deliberadamente en la
-- migración de auth (close_rls_authenticated_only.sql). No se reabre acá.
alter table public.ingresos enable row level security;

drop policy if exists "jlp_org_rw" on public.ingresos;
create policy "jlp_org_rw" on public.ingresos
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
where relname = 'ingresos' and relnamespace = 'public'::regnamespace::oid;

-- Debe verse "jlp_org_rw" con roles = {authenticated} (sin anon).
select tablename, policyname, roles, cmd, qual
from pg_policies
where schemaname = 'public' and tablename = 'ingresos';
