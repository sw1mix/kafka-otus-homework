# Домашнее задание 4: Kafka Streams

Приложение Kafka Streams для подсчета количества событий с одинаковыми key в рамках сессии 5 минут.

## Описание

Приложение читает события из топика `events`, группирует их по key и подсчитывает количество событий в рамках сессии 5 минут (session window). Результаты записываются в топик `events-count` и выводятся в консоль.

## Структура проекта

- `docker-compose.yml` - конфигурация для запуска Kafka
- `pom.xml` - Maven конфигурация проекта
- `src/main/java/ru/otus/kafka/streams/EventCounterApp.java` - основное приложение Kafka Streams
- `src/main/resources/logback.xml` - конфигурация логирования
- `create_topics.py` - скрипт для создания топиков
- `README.md` - инструкция по использованию

## Требования

- Java 11 или выше
- Maven 3.6+
- Docker и Docker Compose

## Установка и запуск

### 1. Запуск Kafka

```bash
cd hw-4
docker-compose up -d
```

Дождитесь полного запуска Kafka (проверьте статус: `docker-compose ps`).

### 2. Создание топиков

```bash
python3 create_topics.py
```

Будут созданы топики:
- `events` - входной топик для событий
- `events-count` - выходной топик с результатами подсчета

### 3. Сборка приложения

```bash
mvn clean package
```

После сборки будет создан JAR файл: `target/kafka-streams-app-1.0-SNAPSHOT-jar-with-dependencies.jar`

### 4. Запуск приложения Kafka Streams

```bash
java -jar target/kafka-streams-app-1.0-SNAPSHOT-jar-with-dependencies.jar
```

Приложение начнет обрабатывать события из топика `events`.

### 5. Отправка тестовых сообщений

В другом терминале используйте console producer для отправки сообщений:

```bash
docker-compose exec kafka kafka-console-producer \
    --topic events \
    --bootstrap-server localhost:9092 \
    --property "parse.key=true" \
    --property "key.separator=:"
```

Затем вводите сообщения в формате `key:value`:
```
user1:event1
user1:event2
user2:event1
user1:event3
user2:event2
```

**Важно:** Используйте одинаковые key для проверки работы сессий. События с одним key, пришедшие в течение 5 минут, будут сгруппированы в одну сессию.

### 6. Просмотр результатов

Результаты будут выводиться в консоль приложения Kafka Streams в формате:
```
>>> Key: user1, Count: 3, Window: [timestamp_start - timestamp_end]
```

Также можно просмотреть результаты из выходного топика:

```bash
docker-compose exec kafka kafka-console-consumer \
    --topic events-count \
    --bootstrap-server localhost:9092 \
    --from-beginning \
    --property print.key=true
```

## Скриншоты работы приложения

- **Отправка сообщений:** [screens/image-send.png](screens/image-send.png)
- **Чтение результатов:** [screens/image-read.png](screens/image-read.png)

## Как работает сессия 5 минут

Session window группирует события по key в сессии на основе времени неактивности:

1. **Первое событие** с key создает новую сессию
2. **Последующие события** с тем же key в течение 5 минут добавляются в ту же сессию
3. Если **прошло более 5 минут** без событий для данного key, сессия закрывается
4. **Новое событие** после закрытия сессии создает новую сессию

Пример:
- `user1:event1` (t=0) → создается сессия
- `user1:event2` (t=2min) → добавляется в сессию
- `user1:event3` (t=4min) → добавляется в сессию
- Пауза 6 минут
- `user1:event4` (t=10min) → создается новая сессия

## Остановка

```bash
# Остановить приложение Kafka Streams (Ctrl+C)
# Остановить Kafka
docker-compose down
```

## Технические детали

### Session Window

- **Таймаут сессии:** 5 минут (300000 мс)
- **Группировка:** по key
- **Агрегация:** count (подсчет количества событий)

### Топики

- **Входной:** `events` (key: String, value: String)
- **Выходной:** `events-count` (key: String, value: String с информацией о счетчике)

### Настройки Kafka Streams

- `application.id`: `event-counter-app`
- `bootstrap.servers`: `localhost:19092`
- `auto.offset.reset`: `earliest` (чтение с начала)
- Используется `WallclockTimestampExtractor` для извлечения времени из сообщений
