-- ============================================================================
-- Tabla liquidaciones: devoluciones de plata ENTRE Enrique y Dayanne, para
-- saldar la deuda 50/50 que generan los gastos con reparto='mitad'. Distinta
-- de reembolsos (que es SpA→socio, ver setup_reembolsos.sql) — no se mezclan.
-- Mismo estilo que reembolsos: id text generado en el cliente con uid(), NO
-- serial. Requiere haber corrido antes alter_gastos_financiado_reparto.sql.
--
-- Copia y pega TODO esto en Supabase SQL Editor (Settings → SQL Editor → New
-- query) y ejecútalo una sola vez. Es idempotente.
-- ============================================================================

-- 1) TABLA -------------------------------------------------------------------
create table if not exists public.liquidaciones (
  id           text primary key,
  org_id       text not null,
  fecha        date not null,
  de_socio     text not null check (de_socio in ('enrique','dayanne')),
  a_socio      text not null check (a_socio in ('enrique','dayanne')),
  monto        numeric not null default 0,
  metodo_pago  text,
  notas        text,
  autor        text references public.usuarios(id),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  constraint liquidaciones_de_a_distintos check (de_socio <> a_socio)
);

-- Trigger para mantener updated_at al día (usado por el merge last-write-wins
-- del cliente, igual que en gastos/notas/eventos/ingresos/reembolsos/archivos).
create or replace function public.set_updated_at_liquidaciones()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_liquidaciones_updated_at on public.liquidaciones;
create trigger trg_liquidaciones_updated_at
  before update on public.liquidaciones
  for each row
  execute function public.set_updated_at_liquidaciones();

create index if not exists idx_liquidaciones_org_id on public.liquidaciones (org_id);

-- 2) RLS -----------------------------------------------------------------
-- SOLO "authenticated" — el acceso anon ya se cerró deliberadamente en la
-- migración de auth (close_rls_authenticated_only.sql). No se reabre acá.
alter table public.liquidaciones enable row level security;

drop policy if exists "jlp_org_rw" on public.liquidaciones;
create policy "jlp_org_rw" on public.liquidaciones
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
where relname = 'liquidaciones' and relnamespace = 'public'::regnamespace::oid;

-- Debe verse "jlp_org_rw" con roles = {authenticated} (sin anon).
select tablename, policyname, roles, cmd, qual
from pg_policies
where schemaname = 'public' and tablename = 'liquidaciones';
