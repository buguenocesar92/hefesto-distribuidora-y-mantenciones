"""Genera CSV de preparación para mapear y revisar en Odoo; no escribe al ERP."""
import csv,json,sys
from pathlib import Path
if len(sys.argv)!=3: raise SystemExit('Uso: python3 migration/prepare_odoo.py respaldo.json carpeta-salida')
p=json.loads(Path(sys.argv[1]).read_text());s=p.get('state',p)
if s.get('format')!='hefesto-mantenciones':raise SystemExit('Formato incompatible')
o=Path(sys.argv[2]);o.mkdir(parents=True,exist_ok=True)
def save(name,fields,rows):
 with (o/name).open('w',newline='',encoding='utf-8-sig') as f:
  w=csv.writer(f);w.writerow(fields);w.writerows(rows)
save('01_contactos.csv',['ID externo Hefesto','Nombre','Contacto','Correo','Teléfono','Dirección'],[['hefesto_customer_'+x['id'],x['name'],x.get('contact',''),x.get('email',''),x.get('phone',''),x.get('address','')] for x in s['customers']])
save('02_equipos.csv',['ID externo Hefesto','Nombre','Código','Número serie','Cliente referencia','Ubicación','Próxima prevención','Intervalo días'],[['hefesto_asset_'+x['id'],x['name'],x['code'],x['serial'],'hefesto_customer_'+x['customerId'],x['location'],x['nextDue'],x['interval']] for x in s['assets']])
save('03_visitas_revision.csv',['ID externo Hefesto','Equipo referencia','Técnico referencia','Fecha','Hora','Duración minutos','Tipo','Estado','Trabajo','Recepción'],[['hefesto_visit_'+x['id'],'hefesto_asset_'+x['assetId'],x['technicianId'],x['date'],x['time'],x['duration'],x['type'],x['status'],x.get('work',''),x.get('receiver','')] for x in s['visits']])
save('04_tecnicos_revision.csv',['ID referencia','Nombre','Especialidad','Teléfono'],[[x['id'],x['name'],x['specialty'],x['phone']] for x in s['technicians']])
save('05_incidentes_revision.csv',['ID','Equipo referencia','Estado','Problema','Resolución'],[[x['id'],'hefesto_asset_'+x['assetId'],x['status'],x['title'],x.get('resolution','')] for x in s['incidents']])
(o/'respaldo_completo.json').write_text(json.dumps(s,ensure_ascii=False,indent=2))
(o/'LEEME.txt').write_text('CSV de preparación, no importación automática. Mapear campos según versión y módulos Odoo. Importar primero contactos, luego equipos, relacionando IDs externos. Visitas, técnicos e incidentes requieren adaptación de estados y relaciones. Checklist, fotos e historial permanecen en respaldo_completo.json. Validar en base de prueba antes de producción. No incluye addon Odoo.\n')
print('Preparación terminada:',o)
