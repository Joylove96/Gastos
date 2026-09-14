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

insert into empresa (org_id,razon_social,rut,fecha_constitucion,regimen,giro,domicilio,
  marca_nombre,marca_clases,marca_estado,cuenta_banco,tarjeta_terminacion,cert_digital,cert_vence,contador)
values ('joylovepets-spa','JoyLovePets SpA','78.422.903-3','2026-05-13',
  'Pro Pyme Transparente (14 D N°8)', null, null,
  'JOYLOVEPETS','18, 28, 35','En trámite de cesión a la SpA (desde 14-09-2026)',
  'BancoEstado MiPyme','0703','e-certchile','2029-07-31', null)
on conflict (org_id) do nothing;
