-- ============================================================================
-- Separación contable por marca (JoyLovePets vs Jevima) para gastos. Mismos
-- valores que ingresos.marca (ver setup_ingresos.sql) — se reutiliza la
-- constante MARCAS del cliente, no se inventan valores nuevos.
--
-- La mayoría de los gastos históricos (constitución, notaría, marca INAPI,
-- certificado digital) son de la EMPRESA, no de una marca en particular. El
-- default 'Común' cubre eso sin forzar una atribución falsa a JoyLovePets o
-- Jevima — el usuario reclasifica a mano los que sí correspondan a una marca.
--
-- Copia y pega TODO esto en Supabase SQL Editor (Settings → SQL Editor → New
-- query) y ejecútalo una sola vez. Es idempotente.
-- ============================================================================

-- 1) COLUMNA NUEVA EN gastos ---------------------------------------------------
alter table public.gastos add column if not exists marca text not null default 'Común';

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'gastos_marca_check') then
    alter table public.gastos
      add constraint gastos_marca_check
      check (marca in ('JoyLovePets','Jevima','Común'));
  end if;
end $$;

-- 2) BACKFILL ------------------------------------------------------------------
-- Los registros existentes ya quedaron en 'Común' por el DEFAULT del ADD
-- COLUMN (Postgres lo aplica también a las filas existentes sin reescribir la
-- tabla). Este UPDATE es redundante pero explícito. NO se atribuye ningún
-- gasto histórico a JoyLovePets ni a Jevima — eso lo hace el usuario a mano.
update public.gastos set marca = 'Común' where marca is null;

-- ============================================================================
-- VERIFICACIÓN
-- ============================================================================

-- Los 10 gastos existentes deben aparecer todos en 'Común'.
select marca, count(*)
from public.gastos
group by marca
order by marca;

-- No debe quedar ningún gasto sin marca.
select count(*) as sin_marca from public.gastos where marca is null;
