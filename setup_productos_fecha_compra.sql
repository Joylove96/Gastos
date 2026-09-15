-- Fecha de compra en productos: permite ordenar el Inventario cronológicamente
-- (más reciente arriba) sin afectar Panel IVA / Rentabilidad, que usan
-- compras/compra_lineas por separado. fecha_compra_aprox marca cuando la fecha
-- no es exacta (ej. los Uppipets, cargados en agosto sin fecha de compra real).

alter table public.productos add column if not exists fecha_compra date;
alter table public.productos add column if not exists fecha_compra_aprox boolean not null default false;

-- Backfill desde compras.fecha para los productos con compra_id (Petegou, Compras
-- Aquí, Mercado Libre — sept 2026).
update public.productos p
   set fecha_compra = c.fecha,
       updated_at = now()
  from public.compras c
 where p.compra_id = c.id;

-- Uppipets: sin compra formal registrada, fecha aproximada (aprox. finales de abril
-- 2026, según lo reportado por el usuario — no hay fecha exacta).
update public.productos
   set fecha_compra = '2026-04-15',
       fecha_compra_aprox = true,
       updated_at = now()
 where sku like 'UPP-%';
