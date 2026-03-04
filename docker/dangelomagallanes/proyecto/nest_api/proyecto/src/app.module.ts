import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConfigModule } from '@nestjs/config';
import { ServeStaticModule } from '@nestjs/serve-static';
import { join } from 'path';
import { PokemonModule } from './pokemon/pokemon.module';
import { PeliculasModule } from './peliculas/peliculas.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    ServeStaticModule.forRoot({
      rootPath: join(__dirname, '..', 'public'),
    }),
    TypeOrmModule.forRoot({
      type: 'postgres',
      host: process.env.DB_HOST || 'localhost',
      port: parseInt(process.env.DB_PORT || '5432') || 5432,
      username: process.env.DB_USER || 'pokemonuser',
      password: process.env.DB_PASSWORD || 'pokemonpass123',
      database: process.env.DATABASE || 'pokemondb',
      autoLoadEntities: true,
      synchronize: true,
    }),
    PokemonModule,
    PeliculasModule,
  ],
})
export class AppModule {}
