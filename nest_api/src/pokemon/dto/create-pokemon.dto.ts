import { IsString, IsNumber, IsNotEmpty } from 'class-validator';

export class CreatePokemonDto {
  @IsString()
  @IsNotEmpty()
  nombre: string;

  @IsString()
  @IsNotEmpty()
  tipo: string;

  @IsNumber()
  hp: number;

  @IsNumber()
  ataque: number;

  @IsNumber()
  defensa: number;
}
