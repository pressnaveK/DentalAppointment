import { Module, Controller, Get } from '@nestjs/common';

@Controller()
export class AppController {
  @Get('health')
  healthCheck() {
    return { status: 'healthy', service: 'user-service' };
  }

  @Get()
  getHello() {
    return { message: 'ChatAppointment User Service', version: '1.0.0' };
  }
}

@Module({
  imports: [],
  controllers: [AppController],
})
export class AppModule {}
