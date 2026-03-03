import { IsString, IsNumber, IsNotEmpty, IsDateString } from 'class-validator';

export class CreatePeliculaDto {
  @IsString()
  @IsNotEmpty()
  titulo: string;

  @IsString()
  @IsNotEmpty()
  director: string;

  @IsString()
  @IsNotEmpty()
  genero: string;

  @IsDateString()
  fechaEstreno: Date;

  @IsNumber()
  duracion: number;
}
