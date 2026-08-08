-- ============================================================================
-- ROLLBACK de close_rls_authenticated_only.sql.
--
-- Úsalo si, tras cerrar el candado (Fase C), algún dispositivo con el bundle
-- viejo del cliente queda atascado sin poder sincronizar (por ejemplo, un
-- teléfono con la PWA instalada que no ha recargado app.js/auth.js todavía).
-- Esto vuelve a abrir el acceso a "anon" en las 6 tablas y en storage.objects,
-- exactamente al estado que tenían antes de Fase C — mismo comportamiento que
-- corriendo fix_rls_authenticated.sql + setup_sync_archivos.sql originales.
--
-- OJO: "usuarios" vuelve a su estado original real (solo "anon", SIN
-- "authenticated") — así estaba antes de Fase C, no es un error.
--
-- Copia y pega TODO esto en Supabase SQL Editor y ejecútalo una sola vez.
-- Es idempotente.
-- ============================================================================

ALTER POLICY "jlp_org_rw" ON "public"."gastos"    TO anon, authenticated;
ALTER POLICY "jlp_org_rw" ON "public"."notas"     TO anon, authenticated;
ALTER POLICY "jlp_org_rw" ON "public"."eventos"   TO anon, authenticated;
ALTER POLICY "jlp_org_rw" ON "public"."log"       TO anon, authenticated;
ALTER POLICY "jlp_org_rw" ON "public"."archivos"  TO anon, authenticated;

ALTER POLICY "jlp_permissive_no_org" ON "public"."usuarios" TO anon;

ALTER POLICY "archivos_storage_select" ON "storage"."objects" TO anon, authenticated;
ALTER POLICY "archivos_storage_insert" ON "storage"."objects" TO anon, authenticated;
ALTER POLICY "archivos_storage_delete" ON "storage"."objects" TO anon, authenticated;

-- ============================================================================
-- VERIFICACIÓN
-- gastos/notas/eventos/log/archivos y las 3 de storage deben mostrar
-- {anon,authenticated}. usuarios debe mostrar SOLO {anon}.
-- ============================================================================
select schemaname, tablename, policyname, roles, cmd
from pg_policies
where (schemaname = 'public' and tablename in ('gastos','notas','eventos','log','usuarios','archivos'))
   or (schemaname = 'storage' and tablename = 'objects' and policyname like 'archivos_storage_%')
order by schemaname, tablename, policyname;
