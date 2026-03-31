## Запуск

### Требования
- Docker Desktop

### Старт
1. Создать файл `.env.docker` из примера `.env.docker.example` (или отредактировать существующий `.env.docker`).
2. Запустить:
   ```bash
   docker-compose up -d --build
   ```
3. Открыть в браузере: http://localhost

### Остановка
```bash
docker-compose down
```
