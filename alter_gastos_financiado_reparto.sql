-- ============================================================================
-- Deuda ENTRE SOCIOS (Enrique ↔ Dayanne), distinta de la deuda SpA→socios que
-- ya muestra Cuenta Corriente (reembolsos.sql). Los socios reparten TODO
-- gasto 50/50 sin importar quién puso la plata en el momento; entidad_paga
-- solo registra a nombre de quién quedó el documento (efecto tributario, NO
-- se toca). financiado_por separa eso: de qué bolsillo salió la plata real.
--
-- Copia y pega TODO esto en Supabase SQL Editor (Settings → SQL Editor → New
-- query) y ejecútalo una sola vez. Es idempotente.
-- ============================================================================

-- 1) COLUMNAS NUEVAS EN gastos ------------------------------------------------
alter table public.gastos add column if not exists financiado_por text;
alter table public.gastos add column if not exists reparto text not null default 'mitad';

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'gastos_financiado_por_check') then
    alter table public.gastos
      add constraint gastos_financiado_por_check
      check (financiado_por is null or financiado_por in ('enrique','dayanne','ambos'));
  end if;

  if not exists (select 1 from pg_constraint where conname = 'gastos_reparto_check') then
    alter table public.gastos
      add constraint gastos_reparto_check
      check (reparto in ('mitad','completo'));
  end if;
end $$;

-- 2) BACKFILL de registros existentes ----------------------------------------
-- reparto ya quedó en 'mitad' por el DEFAULT del ADD COLUMN (Postgres lo
-- aplica también a las filas existentes sin reescribir la tabla). Este UPDATE
-- es redundante pero explícito, y no toca filas que ya cumplan.
update public.gastos set reparto = 'mitad' where reparto is null;

-- financiado_por: derivado de entidad_paga. 'SpA' queda en NULL a propósito
-- (la SpA no tenía cuenta bancaria en esas fechas — alguien puso la plata
-- personalmente, pero se completa caso por caso a mano desde el formulario).
-- NO se toca entidad_paga ni ningún otro campo.
update public.gastos
set financiado_por = case entidad_paga
  when 'Personal (yo)' then 'enrique'
  when 'Personal (socia)' then 'dayanne'
  else null
end
where financiado_por is null;

-- ============================================================================
-- VERIFICACIÓN
-- ============================================================================

-- financiado_por poblado para los no-SpA, NULL para SpA (a completar a mano).
select entidad_paga, financiado_por, reparto, count(*)
from public.gastos
group by entidad_paga, financiado_por, reparto
order by entidad_paga;

-- Ningún gasto debe quedar con reparto NULL.
select count(*) as sin_reparto from public.gastos where reparto is null;
