-- ============================================================================
-- Bug: gastos/notas/eventos/log tienen autor -> usuarios.id (foreign key),
-- pero la tabla public.usuarios estaba vacia. Cualquier registro nuevo creado
-- desde la app (que SI manda autor: 'enrique' | 'dayanne') violaba la FK y
-- fallaba al sincronizar en silencio (solo quedaba local en ese dispositivo).
-- Los gastos existentes funcionan porque se insertaron por SQL sin autor
-- (NULL en una FK siempre es valido, por eso no fallaban).
--
-- Fix: poblar usuarios con los dos perfiles que ya usa la app (mismos ids,
-- nombres y avatares que la constante PERSONAS en app.js).
-- Idempotente: se puede correr mas de una vez sin duplicar.
-- ============================================================================

insert into public.usuarios (id, nombre, mascota, avatar) values
  ('enrique', 'Enrique', 'Tequila', './avatar-tequila.png'),
  ('dayanne', 'Dayanne', 'Canela', './avatar-canela.png')
on conflict (id) do update
  set nombre = excluded.nombre,
      mascota = excluded.mascota,
      avatar = excluded.avatar;

-- VERIFICACION
select * from public.usuarios order by id;
