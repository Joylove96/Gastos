-- BACKFILL NETO/IVA EN TABLA GASTOS
-- Corrección: Notaría ($10k, 2026-07-14) y Conservador ($10k, 2026-07-13)
-- fueron pagadas en EFECTIVO, sin factura → tipo_documento='Sin documento', iva=0

-- VERIFICACIÓN INICIAL
SELECT id, fecha, concepto, monto_total, tipo_documento, neto, iva
FROM gastos
ORDER BY fecha DESC;

-- BLOQUE 1: Actualizar Notaría y Conservador (efectivo, sin documento)
UPDATE gastos
SET tipo_documento = 'Sin documento', neto = monto_total, iva = 0
WHERE concepto IN ('Mod. de Poder', 'Dominio vigente (Domicilio tributario)');

-- BLOQUE 2: Actualizar resto de gastos por regla tipo_documento
-- Boleta → iva=0, neto=monto_total
UPDATE gastos
SET iva = 0, neto = monto_total
WHERE tipo_documento = 'Boleta';

-- Sin documento (excepto los 2 que ya actualizamos) → iva=0, neto=monto_total
UPDATE gastos
SET iva = 0, neto = monto_total
WHERE tipo_documento = 'Sin documento' AND neto IS NULL;

-- Factura (o vacío que no sea Notaría/Conservador) → neto = round(monto/1.19), iva = monto - neto
UPDATE gastos
SET neto = ROUND(monto_total / 1.19::numeric, 0),
    iva = monto_total - ROUND(monto_total / 1.19::numeric, 0)
WHERE (tipo_documento = 'Factura' OR tipo_documento IS NULL OR tipo_documento = '')
  AND neto IS NULL;

-- BLOQUE 3: Verificación final
-- Validar que neto + iva = monto_total para cada fila
SELECT
  id, fecha, concepto, monto_total, tipo_documento, neto, iva,
  (neto + iva) AS suma_verificacion,
  CASE
    WHEN (neto + iva) = monto_total THEN '✓ OK'
    ELSE '✗ ERROR: suma no coincide'
  END AS estado
FROM gastos
ORDER BY fecha DESC;

-- RESUMEN FINAL
SELECT
  tipo_documento,
  COUNT(*) as cantidad,
  SUM(monto_total) as total_monto,
  SUM(neto) as total_neto,
  SUM(iva) as total_iva,
  SUM(iva) as iva_recuperable
FROM gastos
GROUP BY tipo_documento
ORDER BY tipo_documento;
