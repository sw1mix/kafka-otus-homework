# Домашнее задание 5: Akka Streams и Alpakka

Приложение на Akka Streams с графом DSL для обработки чисел с использованием broadcast и zip операций.

## Описание

Приложение реализует граф обработки данных:
- Входной поток целых чисел
- Broadcast на 3 потока
- Первый поток: умножение на 10
- Второй поток: умножение на 2
- Третий поток: умножение на 3
- Zip для объединения 3 потоков
- Сложение элементов из 3 потоков

Пример:
```
1 2 3 4 5 -> 1 2 3 4 5 -> 10 20 30 40 50
          -> 1 2 3 4 5 -> 2 4 6 8 10       -> (10,2,3), (20,4,6), (30,6,9), (40,8,12), (50,10,15) -> 15, 30, 45, 60, 75
          -> 1 2 3 4 5 -> 3 6 9 12 15
```

## Структура проекта

- `build.sbt` - конфигурация SBT проекта
- `src/main/scala/ru/otus/kafka/streams/StreamsGraphApp.scala` - основное приложение с графом DSL
- `src/main/scala/ru/otus/kafka/streams/KafkaStreamsGraphApp.scala` - приложение с интеграцией Kafka (задача со *)
- `src/main/scala/ru/otus/kafka/streams/KafkaProducerApp.scala` - простой producer для отправки чисел в Kafka
- `docker-compose.yml` - конфигурация для запуска Kafka
- `create_topics.py` - скрипт для создания топиков

## Требования

- Scala 2.13+
- SBT 1.8+
- Docker и Docker Compose
- Java 11 или выше

## Установка и запуск

### 1. Запуск Kafka (для задачи со *)

```bash
cd hw-5
docker-compose up -d
```

Дождитесь полного запуска Kafka.

### 2. Создание топиков (для задачи со *)

```bash
python3 create_topics.py
```

Будут созданы топики:
- `numbers-input` - входной топик для чисел
- `numbers-output` - выходной топик с результатами

### 3. Сборка проекта

```bash
sbt compile
```

### 4. Запуск основного приложения (часть 1)

```bash
sbt "runMain ru.otus.kafka.streams.StreamsGraphApp"
```

Приложение обработает числа от 1 до 5 и выведет результаты:
```
>>> Результат: 15
>>> Результат: 30
>>> Результат: 45
>>> Результат: 60
>>> Результат: 75
```

### 5. Запуск приложения с Kafka (задача со *)

**Вариант 1: Использование встроенного Producer**

В одном терминале запустите Consumer:
```bash
sbt "runMain ru.otus.kafka.streams.KafkaStreamsGraphApp"
```

В другом терминале запустите Producer:
```bash
sbt "runMain ru.otus.kafka.streams.KafkaProducerApp"
```

**Вариант 2: Использование console producer**

В одном терминале запустите Consumer:
```bash
sbt "runMain ru.otus.kafka.streams.KafkaStreamsGraphApp"
```

В другом терминале отправьте числа через console producer:
```bash
docker-compose exec kafka kafka-console-producer \
    --topic numbers-input \
    --bootstrap-server localhost:9092
```

Затем вводите числа по одному:
```
1
2
3
4
5
```

Результаты будут отправлены в топик `numbers-output`. Для просмотра результатов:

```bash
docker-compose exec kafka kafka-console-consumer \
    --topic numbers-output \
    --bootstrap-server localhost:9092 \
    --from-beginning
```

## Скриншоты работы приложения

- **Основное приложение (без Kafka):** [screens/without_star.png](screens/without_star.png)
- **Приложение с Kafka (задача со *):** [screens/with_star.png](screens/with_star.png)
