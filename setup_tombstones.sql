-- Tombstones: registro permanente de filas borradas.
-- Resuelve el bug de "zombis": un dispositivo con localStorage viejo re-pusheaba
-- filas ya borradas remotamente y las resucitaba (pasó el 10-08-2026 con 2
-- reembolsos y 1 liquidación que se borraron por UI el 11-08 y el 12-08).
--
-- El cliente (app.js) trae esta lista ANTES de mergear y ANTES de cada push,
-- y filtra cualquier fila cuyo id esté aquí. Los tombstones son permanentes:
-- nunca se purgan ni se vencen.

create table if not exists public.tombstones (
  id         text primary key,              -- '<entidad>:<ref_id>', idempotente
  org_id     text not null,
  entidad    text not null,                 -- 'gastos','productos','reembolsos',...
  ref_id     text not null,                 -- id de la fila borrada
  borrado_at timestamptz not null default now(),
  autor      text
);

alter table public.tombstones enable row level security;

drop policy if exists jlp_org_rw on public.tombstones;
create policy jlp_org_rw on public.tombstones
  for all to authenticated
  using (org_id = 'joylovepets-spa')
  with check (org_id = 'joylovepets-spa');

create index if not exists tombstones_org_entidad_idx on public.tombstones (org_id, entidad);
