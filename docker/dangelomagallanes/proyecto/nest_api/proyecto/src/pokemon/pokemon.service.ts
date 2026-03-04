import { Injectable, OnModuleInit } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Pokemon } from './pokemon.entity';
import { CreatePokemonDto } from './dto/create-pokemon.dto';
import { UpdatePokemonDto } from './dto/update-pokemon.dto';

@Injectable()
export class PokemonService implements OnModuleInit {
  constructor(
    @InjectRepository(Pokemon)
    private pokemonRepository: Repository<Pokemon>,
  ) {}

  async onModuleInit() {
    const count = await this.pokemonRepository.count();
    if (count === 0) {
      const seedData: CreatePokemonDto[] = [
        { nombre: 'Pikachu', tipo: 'Eléctrico', hp: 35, ataque: 55, defensa: 40 },
        { nombre: 'Charizard', tipo: 'Fuego', hp: 78, ataque: 84, defensa: 78 },
        { nombre: 'Blastoise', tipo: 'Agua', hp: 79, ataque: 83, defensa: 100 },
        { nombre: 'Venusaur', tipo: 'Planta', hp: 80, ataque: 82, defensa: 83 },
        { nombre: 'Bulbasaur', tipo: 'Planta', hp: 45, ataque: 49, defensa: 49 },
        { nombre: 'Gengar', tipo: 'Fantasma', hp: 60, ataque: 65, defensa: 60 },
        { nombre: 'Snorlax', tipo: 'Normal', hp: 160, ataque: 110, defensa: 65 },
        { nombre: 'Mewtwo', tipo: 'Psíquico', hp: 106, ataque: 110, defensa: 90 },
        { nombre: 'Gyarados', tipo: 'Agua', hp: 95, ataque: 125, defensa: 79 },
        { nombre: 'Dragonite', tipo: 'Dragón', hp: 91, ataque: 134, defensa: 95 },
        { nombre: 'Jolteon', tipo: 'Eléctrico', hp: 65, ataque: 65, defensa: 60 },
        { nombre: 'Umbreon', tipo: 'Normal', hp: 95, ataque: 65, defensa: 110 },
        { nombre: 'Ninetales', tipo: 'Fuego', hp: 73, ataque: 76, defensa: 75 },
        { nombre: 'Lucario', tipo: 'Normal', hp: 70, ataque: 110, defensa: 70 },
        { nombre: 'Crobat', tipo: 'Fantasma', hp: 85, ataque: 90, defensa: 80 },
        { nombre: 'Lapras', tipo: 'Agua', hp: 130, ataque: 85, defensa: 80 },
      ];
      await this.pokemonRepository.save(seedData);
      console.log('Pokemon seed data inserted');
    }
  }

  findAll(): Promise<Pokemon[]> {
    return this.pokemonRepository.find();
  }

  findOne(id: number): Promise<Pokemon | null> {
    return this.pokemonRepository.findOneBy({ id });
  }

  findByNombre(nombre: string): Promise<Pokemon[]> {
    return this.pokemonRepository
      .createQueryBuilder('pokemon')
      .where('LOWER(pokemon.nombre) LIKE LOWER(:nombre)', { nombre: `%${nombre}%` })
      .getMany();
  }

  findByTipo(tipo: string): Promise<Pokemon[]> {
    return this.pokemonRepository
      .createQueryBuilder('pokemon')
      .where('LOWER(pokemon.tipo) = LOWER(:tipo)', { tipo })
      .getMany();
  }

  findByHpGreaterThan(hp: number): Promise<Pokemon[]> {
    return this.pokemonRepository
      .createQueryBuilder('pokemon')
      .where('pokemon.hp >= :hp', { hp })
      .getMany();
  }

  create(createPokemonDto: CreatePokemonDto): Promise<Pokemon> {
    const pokemon = this.pokemonRepository.create(createPokemonDto);
    return this.pokemonRepository.save(pokemon);
  }

  async update(id: number, updatePokemonDto: UpdatePokemonDto): Promise<Pokemon | null> {
    await this.pokemonRepository.update(id, updatePokemonDto);
    return this.pokemonRepository.findOneBy({ id });
  }

  async remove(id: number): Promise<void> {
    await this.pokemonRepository.delete(id);
  }
}
