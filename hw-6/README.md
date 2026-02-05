# Домашнее задание 6: Kafka Connect с Debezium PostgreSQL CDC

Настройка Kafka Connect с Debezium PostgreSQL CDC Source Connector для отслеживания изменений в базе данных PostgreSQL.

## Описание

Приложение демонстрирует работу Kafka Connect с Debezium PostgreSQL CDC (Change Data Capture) Source Connector:
- Запуск Kafka, PostgreSQL и Kafka Connect
- Настройка Debezium для отслеживания изменений в таблице PostgreSQL
- Автоматическая отправка изменений в Kafka топик

## Структура проекта

- `docker-compose.yml` - конфигурация для Kafka, PostgreSQL и Kafka Connect
- `debezium-connector-config.json` - конфигурация Debezium PostgreSQL Source Connector
- `create_table.sql` - SQL скрипт для создания тестовой таблицы
- `install_debezium.sh` - скрипт для установки Debezium коннектора
- `setup_postgres.sh` - скрипт для настройки PostgreSQL
- `setup_connector.sh` - скрипт для создания коннектора
- `insert_data.sh` - скрипт для добавления данных в таблицу
- `check_kafka_topic.sh` - скрипт для проверки сообщений в Kafka
- `README.md` - инструкция по использованию

## Требования

- Docker и Docker Compose
- curl (для работы с Kafka Connect REST API)
- jq (опционально, для форматирования JSON)

## Установка и запуск

### 1. Запуск всех сервисов

```bash
cd hw-6
docker-compose up -d
```

Дождитесь полного запуска всех сервисов (Kafka, PostgreSQL, Kafka Connect).

Проверка статуса:
```bash
docker-compose ps
```

### 2. Установка Debezium Connector

```bash
./install_debezium.sh
```

Скрипт установит Debezium PostgreSQL Connector в Kafka Connect.

### 3. Настройка PostgreSQL

```bash
./setup_postgres.sh
```

Скрипт:
- Создаст тестовую таблицу `test_table`
- Включит логическую репликацию (REPLICA IDENTITY FULL)
- Добавит начальные тестовые данные

### 4. Создание Debezium Connector

```bash
./setup_connector.sh
```

Скрипт:
- Дождется готовности Kafka Connect
- Создаст Debezium PostgreSQL Source Connector
- Покажет статус коннектора

### 5. Проверка работы

**Добавление данных в таблицу:**
```bash
./insert_data.sh
```

**Проверка сообщений в Kafka:**
```bash
./check_kafka_topic.sh
```

Или вручную:
```bash
docker-compose exec kafka kafka-console-consumer \
    --bootstrap-server localhost:9092 \
    --topic postgres-server.public.test_table \
    --from-beginning
```

## Проверка статуса коннектора

```bash
# Список всех коннекторов
curl http://localhost:8083/connectors

# Статус конкретного коннектора
curl http://localhost:8083/connectors/postgres-source-connector/status | jq '.'

# Конфигурация коннектора
curl http://localhost:8083/connectors/postgres-source-connector/config | jq '.'
```

## Тестирование изменений

### Добавление записи

```bash
docker-compose exec -T postgres psql -U postgres -d testdb <<EOF
INSERT INTO test_table (name, email) VALUES ('New User', 'newuser@example.com');
EOF
```

### Обновление записи

```bash
docker-compose exec -T postgres psql -U postgres -d testdb <<EOF
UPDATE test_table SET email = 'updated@example.com' WHERE name = 'Alice';
EOF
```

### Удаление записи

```bash
docker-compose exec -T postgres psql -U postgres -d testdb <<EOF
DELETE FROM test_table WHERE name = 'Bob';
EOF
```

Все изменения автоматически появятся в Kafka топике `postgres-server.public.test_table`.

## Структура сообщений в Kafka

Debezium создает сообщения в формате JSON с информацией об изменении:

**Для INSERT:**
```json
{
  "before": null,
  "after": {
    "id": 1,
    "name": "Alice",
    "email": "alice@example.com",
    "created_at": "2024-01-12T20:00:00Z"
  },
  "source": {
    "version": "2.3.0",
    "connector": "postgresql",
    "name": "postgres-server",
    "ts_ms": 1705089600000,
    "snapshot": "false",
    "db": "testdb",
    "sequence": null,
    "schema": "public",
    "table": "test_table",
    "txId": 123,
    "lsid": null,
    "xmin": null
  },
  "op": "c",
  "ts_ms": 1705089600000
}
```

**Для UPDATE:**
```json
{
  "before": {
    "id": 1,
    "name": "Alice",
    "email": "alice@example.com"
  },
  "after": {
    "id": 1,
    "name": "Alice",
    "email": "updated@example.com"
  },
  "op": "u",
  ...
}
```

**Для DELETE:**
```json
{
  "before": {
    "id": 2,
    "name": "Bob",
    "email": "bob@example.com"
  },
  "after": null,
  "op": "d",
  ...
}
```

## Остановка

```bash
# Остановить все сервисы
docker-compose down

# Остановить и удалить volumes (включая данные PostgreSQL)
docker-compose down -v
```

## Технические детали

### Debezium PostgreSQL Connector

- **Версия:** 2.3.0
- **Plugin:** pgoutput (встроенный в PostgreSQL 10+)
- **Топик:** `postgres-server.public.test_table`
- **Формат:** JSON с схемами

### Настройки коннектора

- `table.include.list`: `public.test_table` - отслеживаемая таблица
- `plugin.name`: `pgoutput` - плагин логической репликации
- `transforms.unwrap.type`: `ExtractNewRecordState` - извлечение только новых записей
- `key.converter` и `value.converter`: `JsonConverter` - конвертация в JSON

### Топики Kafka Connect

- `docker-connect-configs` - конфигурации коннекторов
- `docker-connect-offsets` - офсеты коннекторов
- `docker-connect-status` - статусы коннекторов
- `postgres-server.public.test_table` - данные из таблицы
