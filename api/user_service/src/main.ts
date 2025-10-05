import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  
  // Enable CORS
  app.enableCors({
    origin: true, // Configure appropriately for production
    credentials: true,
  });
  //jkjkjkj jkjkjk kjjkjghg jk jkjkj
  
  await app.listen(process.env.PORT ?? 3000);
}
bootstrap();
