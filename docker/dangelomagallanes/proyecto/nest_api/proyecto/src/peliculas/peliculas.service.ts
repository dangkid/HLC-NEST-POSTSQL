import { Injectable, OnModuleInit } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between } from 'typeorm';
import { Pelicula } from './peliculas.entity';
import { CreatePeliculaDto } from './dto/create-pelicula.dto';
import { UpdatePeliculaDto } from './dto/update-pelicula.dto';

@Injectable()
export class PeliculasService implements OnModuleInit {
  constructor(
    @InjectRepository(Pelicula)
    private peliculaRepository: Repository<Pelicula>,
  ) {}

  async onModuleInit() {
    const count = await this.peliculaRepository.count();
    if (count === 0) {
      const seedData: CreatePeliculaDto[] = [
        { titulo: 'Pokémon: La Película', director: 'Kunihiko Yuyama', genero: 'Animación', fechaEstreno: new Date('1998-07-18'), duracion: 96 },
        { titulo: 'Pokémon 2000', director: 'Kunihiko Yuyama', genero: 'Animación', fechaEstreno: new Date('1999-07-17'), duracion: 84 },
        { titulo: 'Detective Pikachu', director: 'Rob Letterman', genero: 'Aventura', fechaEstreno: new Date('2019-05-10'), duracion: 104 },
        { titulo: 'Pokémon: Mewtwo Strikes Back', director: 'Kunihiko Yuyama', genero: 'Animación', fechaEstreno: new Date('2019-02-12'), duracion: 98 },
        { titulo: 'Pokémon: Lucario y el misterio de Mew', director: 'Kunihiko Yuyama', genero: 'Animación', fechaEstreno: new Date('2005-07-16'), duracion: 103 },
        { titulo: 'Pokémon Heroes', director: 'Kunihiko Yuyama', genero: 'Animación', fechaEstreno: new Date('2002-07-13'), duracion: 80 },
      ];
      await this.peliculaRepository.save(seedData);
      console.log('Peliculas seed data inserted');
    }
  }

  findAll(): Promise<Pelicula[]> {
    return this.peliculaRepository.find();
  }

  findOne(id: number): Promise<Pelicula | null> {
    return this.peliculaRepository.findOneBy({ id });
  }

  findByTitulo(titulo: string): Promise<Pelicula[]> {
    return this.peliculaRepository
      .createQueryBuilder('pelicula')
      .where('LOWER(pelicula.titulo) LIKE LOWER(:titulo)', { titulo: `%${titulo}%` })
      .getMany();
  }

  findByFechas(desde: string, hasta: string): Promise<Pelicula[]> {
    return this.peliculaRepository.find({
      where: {
        fechaEstreno: Between(new Date(desde), new Date(hasta)),
      },
    });
  }

  create(createPeliculaDto: CreatePeliculaDto): Promise<Pelicula> {
    const pelicula = this.peliculaRepository.create(createPeliculaDto);
    return this.peliculaRepository.save(pelicula);
  }

  async update(id: number, updatePeliculaDto: UpdatePeliculaDto): Promise<Pelicula | null> {
    await this.peliculaRepository.update(id, updatePeliculaDto);
    return this.peliculaRepository.findOneBy({ id });
  }

  async remove(id: number): Promise<void> {
    await this.peliculaRepository.delete(id);
  }
}
