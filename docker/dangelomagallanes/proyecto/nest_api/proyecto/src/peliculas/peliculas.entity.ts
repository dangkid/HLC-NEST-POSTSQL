import { Entity, Column, PrimaryGeneratedColumn } from 'typeorm';

@Entity('peliculas')
export class Pelicula {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  titulo: string;

  @Column()
  director: string;

  @Column()
  genero: string;

  @Column({ type: 'date' })
  fechaEstreno: Date;

  @Column()
  duracion: number;
}
