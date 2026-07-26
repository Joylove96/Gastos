-- Backfill de neto/iva para los gastos existentes.
-- Copia y pega en Supabase → SQL Editor → New query. Ejecuta paso a paso (cada bloque por separado)
-- para poder revisar el resultado antes de seguir.

-- ============================================================
-- 0) VERIFICACIÓN PREVIA — mira qué vas a tocar antes de tocarlo
-- ============================================================
select id, fecha, monto_total, tipo_documento, neto, iva, concepto
from gastos
where tipo_documento in ('Boleta', 'Sin documento')
   or tipo_documento is null
   or tipo_documento = ''
order by fecha;

select id, fecha, monto_total, tipo_documento, neto, iva, concepto
from gastos
where tipo_documento = 'Factura';

-- ============================================================
-- 1) Boleta / Sin documento → sin crédito fiscal (IVA no recuperable)
-- ============================================================
update gastos
set iva = 0,
    neto = monto_total
where tipo_documento in ('Boleta', 'Sin documento');

-- ============================================================
-- 2) Vacío o Factura → separa neto/iva (crédito fiscal recuperable, factura a la SpA)
--    neto = monto/1.19 redondeado, iva = monto - neto
-- ============================================================
update gastos
set neto = round(monto_total / 1.19),
    iva = monto_total - round(monto_total / 1.19)
where tipo_documento = 'Factura'
   or tipo_documento is null
   or tipo_documento = '';

-- ============================================================
-- 3) VERIFICACIÓN FINAL
-- ============================================================
select fecha, monto_total, tipo_documento, neto, iva,
       neto + iva as suma,
       (neto + iva = monto_total) as cuadra
from gastos
order by fecha;

select sum(iva) as iva_recuperable_total
from gastos
where tipo_documento not in ('Boleta', 'Sin documento');
