# Домашнее задание 3: Kafka Transactions

Демонстрация работы с транзакциями в Apache Kafka.

## Описание

Приложение демонстрирует работу с транзакциями Kafka:
- Producer отправляет сообщения в двух транзакциях
- Первая транзакция подтверждается (commit)
- Вторая транзакция отменяется (abort)
- Consumer читает только подтвержденные транзакции

## Структура проекта

- `docker-compose.yml` - конфигурация для запуска Kafka
- `producer.py` - приложение для отправки сообщений с транзакциями
- `consumer.py` - приложение для чтения сообщений (только подтвержденные)
- `create_topics.py` - скрипт для создания топиков через Kafka CLI
- `requirements.txt` - зависимости Python

## Установка и запуск

### 1. Запуск Kafka

```bash
cd hw-3
docker-compose up -d
```


### 2. Установка зависимостей Python

```bash
pip3 install --break-system-packages -r requirements.txt
```

Или используйте виртуальное окружение:
```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

**Примечание:** Приложение использует библиотеку `confluent-kafka`, которая более современная и лучше работает с Python 3.12, чем `kafka-python`.

### 3. Создание топиков

**Способ 1: через Python скрипт (рекомендуется)**
```bash
python3 create_topics.py
```

**Способ 2: вручную через docker-compose**
```bash
# Создание topic1
docker-compose exec kafka kafka-topics --create \
    --bootstrap-server localhost:9092 \
    --topic topic1 \
    --partitions 1 \
    --replication-factor 1 \
    --if-not-exists

# Создание topic2
docker-compose exec kafka kafka-topics --create \
    --bootstrap-server localhost:9092 \
    --topic topic2 \
    --partitions 1 \
    --replication-factor 1 \
    --if-not-exists
```

### 4. Запуск Producer

```bash
python3 producer.py
```

Producer выполнит:
- Транзакция 1: отправит по 5 сообщений в каждый топик и подтвердит
- Транзакция 2: отправит по 2 сообщения в каждый топик и отменит

### 5. Запуск Consumer

В другом терминале:

```bash
python3 consumer.py
```

Consumer прочитает только сообщения из подтвержденной транзакции (транзакция 1).

## Ожидаемый результат

Consumer должен вывести:
- 5 сообщений из `topic1` (транзакция 1)
- 5 сообщений из `topic2` (транзакция 1)
- **НЕ** должно быть сообщений из транзакции 2 (она была отменена)

Итого: 10 сообщений из подтвержденной транзакции.

## Остановка

```bash
# Остановить consumer (Ctrl+C)
# Остановить Kafka
docker-compose down
```

## Технические детали

### Producer настройки:
- `transactional_id` - уникальный ID для транзакций
- `enable_idempotence=True` - идемпотентность
- `acks='all'` - подтверждение от всех реплик
- `max_in_flight_requests_per_connection=1` - требуется для транзакций

### Consumer настройки:
- `isolation_level='read_committed'` - читать только подтвержденные транзакции
- `auto_offset_reset='earliest'` - читать с начала топика

## Примечания

- Для работы транзакций в Kafka требуется:
  - `transactional.id` для producer
  - `isolation.level=read_committed` для consumer
  - Поддержка транзакций на стороне брокера (настроено в docker-compose.yml)
