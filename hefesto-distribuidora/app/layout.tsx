import type {Metadata} from 'next';
import './globals.css';
export const metadata:Metadata={title:'Hefesto Distribuidora · Operación mayorista',description:'Pedidos, inventario y distribución B2B en un solo lugar.'};
export default function Layout({children}:{children:React.ReactNode}){return <html lang="es"><body>{children}</body></html>}
