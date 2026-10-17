import type {Metadata} from 'next';import './globals.css';
export const metadata:Metadata={title:'Hefesto Mantenciones · Servicio en terreno',description:'Equipos, planes preventivos y visitas técnicas con evidencia.'};
export default function Layout({children}:{children:React.ReactNode}){return <html lang="es"><body>{children}</body></html>}
