import { Entity, Column, PrimaryGeneratedColumn } from 'typeorm';

@Entity('pokemon')
export class Pokemon {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  nombre: string;

  @Column()
  tipo: string;

  @Column()
  hp: number;

  @Column()
  ataque: number;

  @Column()
  defensa: number;
}
