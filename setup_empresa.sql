-- Tabla empresa: 1 fila por org con los datos de constitución y régimen de la SpA.
-- La vista "Info Empresa" (app.js) la lee en solo lectura. La fecha de inicio de
-- actividades NO se guarda acá: vive en config (maneja la lógica de F29/vencimientos)
-- y la vista la muestra desde ahí, para no tener dos fuentes de verdad.

create table if not exists public.empresa (
  org_id              text primary key,
  razon_social        text,
  rut                 text,
  fecha_constitucion  date,
  regimen             text,
  giro                text,
  domicilio           text,
  marca_nombre        text,
  marca_clases        text,
  marca_estado        text,
  cuenta_banco        text,
  tarjeta_terminacion text,
  cert_digital        text,
  cert_vence          date,
  contador            text,
  updated_at          timestamptz not null default now()
);

alter table public.empresa enable row level security;
drop policy if exists jlp_org_rw on public.empresa;
create policy jlp_org_rw on public.empresa
  for all to authenticated
  using (org_id = 'joylovepets-spa') with check (org_id = 'joylovepets-spa');
drop trigger if exists set_updated_at_empresa on public.empresa;
create trigger set_updated_at_empresa before update on public.empresa
  for each row execute function public.set_updated_at();

alter table public.empresa add column if not exists mercado_pago text;
alter table public.empresa add column if not exists banco_estado text;
alter table public.empresa add column if not exists dte text;
alter table public.empresa add column if not exists giro_folio text;

insert into empresa (org_id,razon_social,rut,fecha_constitucion,regimen,giro,domicilio,
  marca_nombre,marca_clases,marca_estado,cuenta_banco,tarjeta_terminacion,cert_digital,cert_vence,
  contador,mercado_pago,banco_estado,dte,giro_folio)
values ('joylovepets-spa','JoyLovePets SpA','78.422.903-3','2026-05-13',
  'Pro Pyme Transparente (14 D N°8)',
  'Comercializadora de accesorios y alimentos para mascotas, con énfasis en venta online.', null,
  'JOYLOVEPETS','18, 28, 35','En trámite de cesión a la SpA (desde 14-09-2026)',
  'BancoEstado MiPyme','0703','e-certchile','2029-07-31',
  'Sin contador humano (aún)','Activo','Activo y financiado','Factura + boleta habilitadas',
  'Folio 16537290 · 02-07-2026')
on conflict (org_id) do nothing;

-- Actividades económicas registradas ante el SII (giro oficial).
create table if not exists public.actividades (
  org_id      text not null,
  codigo      text not null,
  descripcion text,
  rol         text,
  iva         boolean not null default true,
  orden       int not null default 0,
  updated_at  timestamptz not null default now(),
  primary key (org_id, codigo)
);
alter table public.actividades enable row level security;
drop policy if exists jlp_org_rw on public.actividades;
create policy jlp_org_rw on public.actividades
  for all to authenticated
  using (org_id = 'joylovepets-spa') with check (org_id = 'joylovepets-spa');
drop trigger if exists set_updated_at_actividades on public.actividades;
create trigger set_updated_at_actividades before update on public.actividades
  for each row execute function public.set_updated_at();

insert into public.actividades (org_id,codigo,descripcion,rol,iva,orden) values
 ('joylovepets-spa','477391','Venta al por menor de alimento y accesorios para mascotas en comercios especializados','Principal',true,1),
 ('joylovepets-spa','479100','Venta al por menor por correo, por internet y vía telefónica','Canal (cubre toda categoría online)',true,2),
 ('joylovepets-spa','960901','Servicios de adiestramiento, guardería, peluquería, paseo de mascotas','Secundario (si se activa)',true,3)
on conflict (org_id,codigo) do nothing;
