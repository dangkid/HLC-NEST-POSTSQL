import './globals.css';

export const metadata = {
  title: 'Pokémon Explorer - D\'Angelo Magallanes',
  description: 'Frontend Next.js para la Pokémon API',
};

export default function RootLayout({ children }) {
  return (
    <html lang="es">
      <body>{children}</body>
    </html>
  );
}
