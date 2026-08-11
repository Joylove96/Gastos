-- ============================================================================
-- Vincula ventas (`ingresos`) a un producto del inventario (`productos`),
-- para poder calcular margen = monto_neto - (costo_unitario * cantidad).
-- Nullable a propósito: los ingresos existentes quedan en NULL (venta sin
-- costo conocido, como hasta ahora) y el vínculo es opcional al registrar
-- una venta nueva. Sin FK, mismo estilo laxo que financiado_por/reparto en
-- gastos — el cliente es quien controla la referencia.
--
-- Copia y pega TODO esto en Supabase SQL Editor (Settings → SQL Editor → New
-- query) y ejecútalo una sola vez. Es idempotente. Requiere haber corrido
-- antes setup_productos.sql.
-- ============================================================================

alter table public.ingresos add column if not exists producto_id text;

-- ============================================================================
-- VERIFICACIÓN
-- ============================================================================

-- La columna debe existir y todos los ingresos existentes deben quedar NULL.
select count(*) as total, count(producto_id) as con_producto
from public.ingresos;
