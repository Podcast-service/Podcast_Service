# Podcast_Service

Общий production-compose для сервисов платформы подкастов.

## Speech Service

`speech_service` использует Kafka, S3-compatible storage, Whisper и pyannote.
Модель Whisper монтируется из `${WHISPER_MODELS_PATH:-/home/deploy/models}` в
`/models`. Минимальные переменные в `/home/deploy/.env`:

```env
S3_ACCESS_KEY_ID=<secret>
S3_SECRET_ACCESS_KEY=<secret>
WHISPER_MODELS_PATH=/home/deploy/models
WHISPER_MODEL_PATH=/models/ggml-medium.bin
PYANNOTE_HF_TOKEN=<secret>
SUBTITLE_MAX_CONCURRENT_JOBS=1
```

Обычный CPU-запуск:

```bash
docker compose \
  --env-file /home/deploy/.env \
  -f docker-compose.yml \
  up -d speech_service
```

### NVIDIA GPU

На сервере должны быть установлены NVIDIA driver и NVIDIA Container Toolkit.
CUDA-образ публикуется с суффиксом `-cuda`, например `latest-cuda` или
`abcdef0-cuda`.

Для ручного запуска добавьте GPU override:

```bash
docker compose \
  --env-file /home/deploy/.env \
  -f docker-compose.yml \
  -f docker-compose.gpu.yml \
  up -d speech_service
```

Для автоматического deploy через GitHub Actions добавьте в `/home/deploy/.env`:

```env
SPEECH_SERVICE_GPU_ENABLED=true
PYANNOTE_DEVICE=auto
```

После этого deploy workflow подключит `docker-compose.gpu.yml` при обновлении
`speech_service`.
