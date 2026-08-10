-- ============================================================================
-- Cuenta corriente de socios: reembolsos que la SpA devuelve a Enrique/Dayanne
-- por los gastos que pagaron de su bolsillo (entidad_paga != 'SpA' en gastos).
-- Un reembolso NO es un gasto operativo (no toca m.pagado ni el resultado
-- operacional del card de Flujo de Caja) ni una venta — es la devolución de
-- un préstamo del socio a la empresa. Mismo estilo que "ingresos": id text
-- generado en el cliente con uid(), NO serial.
--
-- Copia y pega TODO esto en Supabase SQL Editor (Settings → SQL Editor → New
-- query) y ejecútalo una sola vez. Es idempotente.
-- ============================================================================

-- 1) TABLA -------------------------------------------------------------------
create table if not exists public.reembolsos (
  id           text primary key,
  org_id       text not null,
  fecha        date not null,
  socio        text not null check (socio in ('enrique','dayanne')),
  monto        numeric not null default 0,
  metodo_pago  text,
  notas        text,
  autor        text references public.usuarios(id),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

-- Trigger para mantener updated_at al día (usado por el merge last-write-wins
-- del cliente, igual que en gastos/notas/eventos/ingresos/archivos).
create or replace function public.set_updated_at_reembolsos()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_reembolsos_updated_at on public.reembolsos;
create trigger trg_reembolsos_updated_at
  before update on public.reembolsos
  for each row
  execute function public.set_updated_at_reembolsos();

create index if not exists idx_reembolsos_org_id on public.reembolsos (org_id);
create index if not exists idx_reembolsos_socio on public.reembolsos (socio);

-- 2) RLS -----------------------------------------------------------------
-- SOLO "authenticated" — el acceso anon ya se cerró deliberadamente en la
-- migración de auth (close_rls_authenticated_only.sql). No se reabre acá.
alter table public.reembolsos enable row level security;

drop policy if exists "jlp_org_rw" on public.reembolsos;
create policy "jlp_org_rw" on public.reembolsos
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
where relname = 'reembolsos' and relnamespace = 'public'::regnamespace::oid;

-- Debe verse "jlp_org_rw" con roles = {authenticated} (sin anon).
select tablename, policyname, roles, cmd, qual
from pg_policies
where schemaname = 'public' and tablename = 'reembolsos';
