'use client';

import { useState, useEffect } from 'react';

const pokemonSprites = {
  'Pikachu': 25, 'Charizard': 6, 'Blastoise': 9, 'Venusaur': 3,
  'Bulbasaur': 1, 'Gengar': 94, 'Snorlax': 143, 'Mewtwo': 150,
  'Gyarados': 130, 'Dragonite': 149, 'Jolteon': 135, 'Umbreon': 197,
  'Ninetales': 38, 'Lucario': 448, 'Crobat': 169, 'Lapras': 131,
};

const typeClasses = {
  'Eléctrico': 'type-electrico', 'Fuego': 'type-fuego',
  'Agua': 'type-agua', 'Planta': 'type-planta',
  'Fantasma': 'type-fantasma', 'Normal': 'type-normal',
  'Psíquico': 'type-psiquico', 'Dragón': 'type-dragon',
};

function getPokemonImage(nombre) {
  const id = pokemonSprites[nombre];
  if (id) {
    return `https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/${id}.png`;
  }
  return `https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/0.png`;
}

export default function Home() {
  const [pokemon, setPokemon] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    // En producción, la API NestJS está en api.dangelomagallanes.me
    const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://api.dangelomagallanes.me';
    
    fetch(`${apiUrl}/pokemon`)
      .then(res => res.json())
      .then(data => {
        setPokemon(data);
        setLoading(false);
      })
      .catch(err => {
        console.error('Error fetching pokemon:', err);
        // Si la API no está disponible, usar datos de ejemplo
        setPokemon([
          { id: 1, nombre: 'Pikachu', tipo: 'Eléctrico', hp: 35, ataque: 55, defensa: 40 },
          { id: 2, nombre: 'Charizard', tipo: 'Fuego', hp: 78, ataque: 84, defensa: 78 },
          { id: 3, nombre: 'Blastoise', tipo: 'Agua', hp: 79, ataque: 83, defensa: 100 },
          { id: 4, nombre: 'Venusaur', tipo: 'Planta', hp: 80, ataque: 82, defensa: 83 },
          { id: 5, nombre: 'Gengar', tipo: 'Fantasma', hp: 60, ataque: 65, defensa: 60 },
          { id: 6, nombre: 'Mewtwo', tipo: 'Psíquico', hp: 106, ataque: 110, defensa: 90 },
          { id: 7, nombre: 'Dragonite', tipo: 'Dragón', hp: 91, ataque: 134, defensa: 95 },
          { id: 8, nombre: 'Snorlax', tipo: 'Normal', hp: 160, ataque: 110, defensa: 65 },
        ]);
        setLoading(false);
      });
  }, []);

  if (loading) return <div className="loading">Cargando Pokémon...</div>;
  if (error) return <div className="error">{error}</div>;

  return (
    <div className="container">
      <header>
        <h1>Pokémon Explorer</h1>
        <p>Proyecto de D'Angelo Magallanes - HLC NestJS + PostgreSQL + Next.js</p>
      </header>

      <div className="pokemon-grid">
        {pokemon.map(p => (
          <div key={p.id} className="pokemon-card">
            <img src={getPokemonImage(p.nombre)} alt={p.nombre} />
            <h3>{p.nombre}</h3>
            <span className={`type-badge ${typeClasses[p.tipo] || 'type-normal'}`}>
              {p.tipo}
            </span>
            <div className="stats">
              <div className="stat">
                <span className="stat-value">{p.hp}</span>
                <span className="stat-label">HP</span>
              </div>
              <div className="stat">
                <span className="stat-value">{p.ataque}</span>
                <span className="stat-label">ATK</span>
              </div>
              <div className="stat">
                <span className="stat-value">{p.defensa}</span>
                <span className="stat-label">DEF</span>
              </div>
            </div>
          </div>
        ))}
      </div>

      <footer>
        <p>&copy; 2026 D'Angelo Magallanes - api.dangelomagallanes.me</p>
      </footer>
    </div>
  );
}
