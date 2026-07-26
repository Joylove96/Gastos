-- Extiende la policy existente "jlp_org_rw" (org_id = 'joylovepets-spa') para que
-- también aplique al rol "authenticated" (usuarios logueados vía auth.js), no solo "anon".
-- No cambia la condición de seguridad (org_id) ni el comportamiento para "anon" — solo
-- agrega el rol que faltaba, que es la causa de que la app logueada vea 0 gastos/notas/eventos/log.

ALTER POLICY "jlp_org_rw" ON "public"."gastos"  TO anon, authenticated;
ALTER POLICY "jlp_org_rw" ON "public"."notas"   TO anon, authenticated;
ALTER POLICY "jlp_org_rw" ON "public"."eventos" TO anon, authenticated;
ALTER POLICY "jlp_org_rw" ON "public"."log"     TO anon, authenticated;

-- Verificación: deberías ver "anon" y "authenticated" en la columna roles para las 4 filas.
SELECT tablename, policyname, roles, qual
FROM pg_policies
WHERE schemaname = 'public' AND tablename IN ('gastos','notas','eventos','log');
