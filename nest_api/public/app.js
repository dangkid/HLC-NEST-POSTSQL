const API_BASE = window.location.origin;

// ─── POKEMON SPRITE MAPPING (PokeAPI official artwork) ───
const pokemonSprites = {
    'Pikachu': 25,
    'Charizard': 6,
    'Blastoise': 9,
    'Venusaur': 3,
    'Bulbasaur': 1,
    'Gengar': 94,
    'Snorlax': 143,
    'Mewtwo': 150,
    'Gyarados': 130,
    'Dragonite': 149,
    'Jolteon': 135,
    'Umbreon': 197,
    'Ninetales': 38,
    'Lucario': 448,
    'Crobat': 169,
    'Lapras': 131
};

function getPokemonImage(nombre) {
    const id = pokemonSprites[nombre];
    if (id) {
        return `https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/${id}.png`;
    }
    return `https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/0.png`;
}

// ─── TAB SWITCHING ───
function switchTab(tab) {
    document.querySelectorAll('.nav-tab').forEach(t => t.classList.remove('active'));
    document.querySelectorAll('.section').forEach(s => s.classList.remove('active'));
    document.querySelector(`[data-tab="${tab}"]`).classList.add('active');
    document.getElementById(`${tab}-section`).classList.add('active');
}

// ─── TYPE CLASS MAPPING ───
function getTypeClass(tipo) {
    const map = {
        'Eléctrico': 'type-electrico',
        'Fuego': 'type-fuego',
        'Agua': 'type-agua',
        'Planta': 'type-planta',
        'Fantasma': 'type-fantasma',
        'Normal': 'type-normal',
        'Psíquico': 'type-psiquico',
        'Dragón': 'type-dragon'
    };
    return map[tipo] || 'type-normal';
}

// ─── RENDER PELÍCULAS ───
function renderPeliculas(peliculas) {
    const grid = document.getElementById('peliculas-grid');
    const count = document.getElementById('peliculas-count');
    count.textContent = `Mostrando ${peliculas.length} película${peliculas.length !== 1 ? 's' : ''}`;

    if (peliculas.length === 0) {
        grid.innerHTML = '<div class="empty-state">No se encontraron películas con esos filtros</div>';
        return;
    }

    grid.innerHTML = peliculas.map(p => {
        const fecha = new Date(p.fechaEstreno).toLocaleDateString('es-ES', { year: 'numeric', month: 'long', day: 'numeric' });
        return `
            <div class="pelicula-card">
                <div class="card-title">${p.titulo}</div>
                <div class="card-info">
                    <div class="info-row">
                        <span class="info-label">Director</span>
                        <span class="info-value">${p.director}</span>
                    </div>
                    <div class="info-row">
                        <span class="info-label">Género</span>
                        <span class="badge">${p.genero}</span>
                    </div>
                    <div class="info-row">
                        <span class="info-label">Estreno</span>
                        <span class="info-value">${fecha}</span>
                    </div>
                    <div class="info-row">
                        <span class="info-label">Duración</span>
                        <span class="info-value">${p.duracion} min</span>
                    </div>
                </div>
            </div>
        `;
    }).join('');
}

// ─── RENDER POKÉMON ───
function renderPokemon(pokemons) {
    const grid = document.getElementById('pokemon-grid');
    const count = document.getElementById('pokemon-count');
    count.textContent = `Mostrando ${pokemons.length} pokémon`;

    if (pokemons.length === 0) {
        grid.innerHTML = '<div class="empty-state">No se encontraron pokémon con esos filtros</div>';
        return;
    }

    grid.innerHTML = pokemons.map(p => `
        <div class="pokemon-card" data-type="${p.tipo}">
            <div class="card-header">
                <span class="card-name">${p.nombre}</span>
                <span class="card-id">#${String(p.id).padStart(3, '0')}</span>
            </div>
            <div class="pokemon-img-wrapper">
                <img src="${getPokemonImage(p.nombre)}" alt="${p.nombre}" class="pokemon-img" loading="lazy">
            </div>
            <span class="type-badge ${getTypeClass(p.tipo)}">${p.tipo}</span>
            <div class="stats-grid">
                <div class="stat">
                    <span class="stat-value stat-hp">${p.hp}</span>
                    <span class="stat-label">HP</span>
                </div>
                <div class="stat">
                    <span class="stat-value stat-atk">${p.ataque}</span>
                    <span class="stat-label">Ataque</span>
                </div>
                <div class="stat">
                    <span class="stat-value stat-def">${p.defensa}</span>
                    <span class="stat-label">Defensa</span>
                </div>
            </div>
        </div>
    `).join('');
}

// ─── FETCH HELPERS ───
async function fetchPeliculas() {
    const res = await fetch(`${API_BASE}/peliculas`);
    return res.json();
}

async function fetchPokemon() {
    const res = await fetch(`${API_BASE}/pokemon`);
    return res.json();
}

// ─── FILTER FUNCTIONS ───
async function filterPeliculas() {
    const titulo = document.getElementById('filter-titulo').value.trim();
    if (!titulo) {
        const data = await fetchPeliculas();
        renderPeliculas(data);
        return;
    }
    const res = await fetch(`${API_BASE}/peliculas/titulo/${encodeURIComponent(titulo)}`);
    const data = await res.json();
    renderPeliculas(data);
}

async function filterPeliculasFecha() {
    const desde = document.getElementById('filter-fecha-desde').value;
    const hasta = document.getElementById('filter-fecha-hasta').value;
    if (!desde || !hasta) return;
    const res = await fetch(`${API_BASE}/peliculas/fechas/${desde}/${hasta}`);
    const data = await res.json();
    renderPeliculas(data);
}

async function resetPeliculas() {
    document.getElementById('filter-titulo').value = '';
    document.getElementById('filter-fecha-desde').value = '';
    document.getElementById('filter-fecha-hasta').value = '';
    const data = await fetchPeliculas();
    renderPeliculas(data);
}

async function filterPokemonNombre() {
    const nombre = document.getElementById('filter-nombre').value.trim();
    if (!nombre) {
        const data = await fetchPokemon();
        renderPokemon(data);
        return;
    }
    const res = await fetch(`${API_BASE}/pokemon/nombre/${encodeURIComponent(nombre)}`);
    const data = await res.json();
    renderPokemon(data);
}

async function filterPokemonTipo() {
    const tipo = document.getElementById('filter-tipo').value;
    if (!tipo) {
        const data = await fetchPokemon();
        renderPokemon(data);
        return;
    }
    const res = await fetch(`${API_BASE}/pokemon/tipo/${encodeURIComponent(tipo)}`);
    const data = await res.json();
    renderPokemon(data);
}

async function filterPokemonHp() {
    const hp = document.getElementById('filter-hp').value.trim();
    if (!hp) {
        const data = await fetchPokemon();
        renderPokemon(data);
        return;
    }
    const res = await fetch(`${API_BASE}/pokemon/hp/${hp}`);
    const data = await res.json();
    renderPokemon(data);
}

async function resetPokemon() {
    document.getElementById('filter-nombre').value = '';
    document.getElementById('filter-tipo').value = '';
    document.getElementById('filter-hp').value = '';
    const data = await fetchPokemon();
    renderPokemon(data);
}

// ─── POPULATE TYPE SELECT ───
async function populateTypes() {
    const data = await fetchPokemon();
    const types = [...new Set(data.map(p => p.tipo))].sort();
    const select = document.getElementById('filter-tipo');
    types.forEach(t => {
        const opt = document.createElement('option');
        opt.value = t;
        opt.textContent = t;
        select.appendChild(opt);
    });
}

// ─── INIT ───
async function init() {
    document.getElementById('peliculas-grid').innerHTML = '<div class="loading">Cargando películas</div>';
    document.getElementById('pokemon-grid').innerHTML = '<div class="loading">Cargando pokémon</div>';

    try {
        const [peliculas, pokemon] = await Promise.all([fetchPeliculas(), fetchPokemon()]);
        renderPeliculas(peliculas);
        renderPokemon(pokemon);
        populateTypes();
    } catch (err) {
        console.error('Error cargando datos:', err);
        document.getElementById('peliculas-grid').innerHTML = '<div class="empty-state">Error al conectar con la API</div>';
        document.getElementById('pokemon-grid').innerHTML = '<div class="empty-state">Error al conectar con la API</div>';
    }
}

init();
