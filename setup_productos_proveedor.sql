-- Proveedor de compra en productos: para saber a quién reclamarle cada producto
-- (garantía, cambio, devolución) sin tener que ir a buscar la compra original.

alter table public.productos add column if not exists proveedor_compra text;

-- Backfill desde compras.proveedor para los productos con compra_id (Petegou,
-- Compras Aquí, Ahorro Pet, Mercado Libre — sept 2026).
update public.productos p
   set proveedor_compra = c.proveedor,
       updated_at = now()
  from public.compras c
 where p.compra_id = c.id;

-- Uppipets: sin compra formal registrada. El gasto original (13-03-2026, boleta
-- $207.540) solo tiene "Uppipet" como concepto, sin razón social ni RUT.
update public.productos
   set proveedor_compra = 'Uppipet',
       updated_at = now()
 where sku like 'UPP-%';
