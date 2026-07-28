-- ============================================================================
-- Sincronización de archivos (documentos y boletas) entre dispositivos.
-- Hoy los archivos viven SOLO en IndexedDB de cada dispositivo (nunca se
-- implementó su sync). Este script crea el bucket + tabla de metadatos +
-- RLS para que app.js pueda subir/descargar archivos vía Supabase Storage,
-- usando IndexedDB solo como caché local.
--
-- Copia y pega TODO esto en Supabase SQL Editor (Settings → SQL Editor → New query)
-- y ejecútalo una sola vez. Es idempotente: se puede volver a correr sin duplicar
-- nada ni romper datos existentes.
-- ============================================================================

-- 1) BUCKET DE STORAGE ------------------------------------------------------
-- Privado (public=false), límite 10 MB por archivo.
insert into storage.buckets (id, name, public, file_size_limit)
values ('archivos', 'archivos', false, 10485760)
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit;

-- 2) TABLA DE METADATOS ------------------------------------------------------
-- Mismo estilo que "gastos": id text (generado en el cliente con uid()),
-- NO serial. storage_path apunta al objeto en el bucket 'archivos'.
create table if not exists public.archivos (
  id           text primary key,
  org_id       text not null,
  tipo         text not null check (tipo in ('documento','boleta')),
  categoria    text,
  gasto_id     text,
  nombre       text not null,
  mime         text,
  tamano       int8,
  fecha        date,
  storage_path text not null,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

-- Trigger para mantener updated_at al día (usado por el merge last-write-wins
-- del cliente, igual que en gastos/notas/eventos). Función con nombre propio
-- para no pisar ninguna función homónima que ya exista para otras tablas.
create or replace function public.set_updated_at_archivos()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_archivos_updated_at on public.archivos;
create trigger trg_archivos_updated_at
  before update on public.archivos
  for each row
  execute function public.set_updated_at_archivos();

-- Índice para el borrado en cascada por gasto (X en app.js) y filtros de UI.
create index if not exists idx_archivos_gasto_id on public.archivos (gasto_id);
create index if not exists idx_archivos_org_id on public.archivos (org_id);

-- 3) RLS EN public.archivos ---------------------------------------------------
-- Mismo patrón que jlp_org_rw en gastos/notas/eventos/log: ambos roles
-- anon Y authenticated. Omitir 'authenticated' fue el bug que dejó el
-- dashboard en 0 gastos — no se repite acá.
alter table public.archivos enable row level security;

drop policy if exists "jlp_org_rw" on public.archivos;
create policy "jlp_org_rw" on public.archivos
  for all
  to anon, authenticated
  using (org_id = 'joylovepets-spa')
  with check (org_id = 'joylovepets-spa');

-- 4) RLS EN storage.objects PARA EL BUCKET 'archivos' ------------------------
-- SELECT (ver/descargar), INSERT (subir) y DELETE (borrar), para anon y
-- authenticated, restringidas al bucket 'archivos'.
drop policy if exists "archivos_storage_select" on storage.objects;
create policy "archivos_storage_select" on storage.objects
  for select
  to anon, authenticated
  using (bucket_id = 'archivos');

drop policy if exists "archivos_storage_insert" on storage.objects;
create policy "archivos_storage_insert" on storage.objects
  for insert
  to anon, authenticated
  with check (bucket_id = 'archivos');

drop policy if exists "archivos_storage_delete" on storage.objects;
create policy "archivos_storage_delete" on storage.objects
  for delete
  to anon, authenticated
  using (bucket_id = 'archivos');

-- ============================================================================
-- VERIFICACIÓN
-- ============================================================================

-- Debe existir el bucket, privado, con límite 10485760 bytes.
select id, name, public, file_size_limit
from storage.buckets
where id = 'archivos';

-- Debe existir la tabla con RLS habilitada.
select relname, relrowsecurity
from pg_class
where relname = 'archivos' and relnamespace = 'public'::regnamespace::oid;

-- Debe verse "jlp_org_rw" con roles {anon,authenticated} para public.archivos.
select tablename, policyname, roles, qual
from pg_policies
where schemaname = 'public' and tablename = 'archivos';

-- Deben verse las 3 policies de storage con roles {anon,authenticated}.
select policyname, roles, cmd
from pg_policies
where schemaname = 'storage' and tablename = 'objects'
  and policyname like 'archivos_storage_%';
