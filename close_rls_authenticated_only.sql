-- ============================================================================
-- FASE C: cerrar el candado. Migra todas las policies de "anon, authenticated"
-- a SOLO "authenticated" en las 6 tablas + storage.objects del bucket 'archivos'.
--
-- Después de correr esto, la publishable key SOLA (sin sesión de Supabase Auth
-- iniciada) ya no podrá leer ni escribir NADA, ni descargar archivos del bucket.
-- Cualquier usuario logueado con la cuenta compartida (joylovemypets@gmail.com)
-- sigue teniendo acceso total, igual que antes.
--
-- Caso especial: "usuarios" tenía su policy "jlp_permissive_no_org" en rol
-- {anon} ÚNICAMENTE (no incluía "authenticated" desde su creación). Este script
-- la deja en {authenticated}, dándole por primera vez acceso al rol logueado y
-- quitándoselo a anon — mismo resultado final que las demás tablas.
--
-- Copia y pega TODO esto en Supabase SQL Editor (Settings → SQL Editor → New
-- query) y ejecútalo una sola vez. Es idempotente: se puede volver a correr
-- sin romper nada. Rollback completo en rollback_rls_anon_authenticated.sql.
-- ============================================================================

ALTER POLICY "jlp_org_rw" ON "public"."gastos"    TO authenticated;
ALTER POLICY "jlp_org_rw" ON "public"."notas"     TO authenticated;
ALTER POLICY "jlp_org_rw" ON "public"."eventos"   TO authenticated;
ALTER POLICY "jlp_org_rw" ON "public"."log"       TO authenticated;
ALTER POLICY "jlp_org_rw" ON "public"."archivos"  TO authenticated;

ALTER POLICY "jlp_permissive_no_org" ON "public"."usuarios" TO authenticated;

ALTER POLICY "archivos_storage_select" ON "storage"."objects" TO authenticated;
ALTER POLICY "archivos_storage_insert" ON "storage"."objects" TO authenticated;
ALTER POLICY "archivos_storage_delete" ON "storage"."objects" TO authenticated;

-- ============================================================================
-- VERIFICACIÓN
-- Todas las filas deben mostrar roles = {authenticated}, sin "anon".
-- ============================================================================
select schemaname, tablename, policyname, roles, cmd
from pg_policies
where (schemaname = 'public' and tablename in ('gastos','notas','eventos','log','usuarios','archivos'))
   or (schemaname = 'storage' and tablename = 'objects' and policyname like 'archivos_storage_%')
order by schemaname, tablename, policyname;
