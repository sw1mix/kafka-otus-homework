# Команды для проверки выполнения задач

## Задача 1: Управление топиками (Topic Management)

### Проверка создания топиков

```bash
# Список всех топиков
docker exec kafka-1 kafka-topics --bootstrap-server kafka-1:9092,kafka-2:9092,kafka-3:9092 --list

# Детальная информация о топике
docker exec kafka-1 kafka-topics --bootstrap-server kafka-1:9092,kafka-2:9092,kafka-3:9092 --describe --topic test-topic-1

# Проверка конфигурации топика
docker exec kafka-1 kafka-configs --bootstrap-server kafka-1:9092,kafka-2:9092,kafka-3:9092 --entity-type topics --entity-name test-topic-1 --describe

# Проверка партиций и репликации
docker exec kafka-1 kafka-topics --bootstrap-server kafka-1:9092,kafka-2:9092,kafka-3:9092 --describe --topic test-topic-1 | grep -E "Partition|Replicas"
```

### Тестирование изменения топика

```bash
# Измените group_vars/all.yml, добавив новый топик или изменив существующий
# Затем примените:
ansible-playbook playbooks/manage-topics.yml

# Проверьте изменения:
docker exec kafka-1 kafka-topics --bootstrap-server kafka-1:9092,kafka-2:9092,kafka-3:9092 --describe --topic test-topic-1
```

### Проверка политик очистки

```bash
# Проверка retention policy
docker exec kafka-1 kafka-configs --bootstrap-server kafka-1:9092,kafka-2:9092,kafka-3:9092 --entity-type topics --entity-name test-topic-1 --describe | grep retention

# Проверка cleanup policy
docker exec kafka-1 kafka-configs --bootstrap-server kafka-1:9092,kafka-2:9092,kafka-3:9092 --entity-type topics --entity-name test-topic-2 --describe | grep cleanup.policy
```

### Автоматический тест

```bash
./scripts/test-topics.sh
```

---

## Задача 2: Управление доступом (ACL/SASL Management)

### Примечание
В текущей конфигурации используется PLAINTEXT, поэтому ACL/SASL не активны. Для полной функциональности необходимо настроить SASL.

### Проверка пользователей (если SASL включен)

```bash
# Список пользователей
docker exec kafka-1 kafka-configs --bootstrap-server kafka-1:9092,kafka-2:9092,kafka-3:9092 --entity-type users --describe

# Проверка конкретного пользователя
docker exec kafka-1 kafka-configs --bootstrap-server kafka-1:9092,kafka-2:9092,kafka-3:9092 --entity-type users --entity-name admin --describe
```

### Проверка ACL правил (если ACL включен)

```bash
# Список всех ACL
docker exec kafka-1 kafka-acls --bootstrap-server kafka-1:9092,kafka-2:9092,kafka-3:9092 --list

# ACL для конкретного пользователя
docker exec kafka-1 kafka-acls --bootstrap-server kafka-1:9092,kafka-2:9092,kafka-3:9092 --list --principal User:admin

# ACL для конкретного топика
docker exec kafka-1 kafka-acls --bootstrap-server kafka-1:9092,kafka-2:9092,kafka-3:9092 --list --topic test-topic-1
```

### Применение конфигурации ACL

```bash
ansible-playbook playbooks/manage-acl.yml
```

---

## Задача 3: Масштабирование кластера (Cluster Scaling)

### Проверка текущего состояния кластера

```bash
# Список запущенных брокеров
docker ps --filter "name=kafka-" --format "table {{.Names}}\t{{.Status}}"

# Проверка подключения каждого брокера
docker exec kafka-1 kafka-broker-api-versions --bootstrap-server localhost:9092
docker exec kafka-2 kafka-broker-api-versions --bootstrap-server localhost:9092
docker exec kafka-3 kafka-broker-api-versions --bootstrap-server localhost:9092
```

### Проверка метаданных кластера

```bash
# Информация о брокерах в кластере
docker exec kafka-1 kafka-broker-api-versions --bootstrap-server kafka-1:9092,kafka-2:9092,kafka-3:9092 | head -20

# Проверка распределения партиций по брокерам
docker exec kafka-1 kafka-topics --bootstrap-server kafka-1:9092,kafka-2:9092,kafka-3:9092 --describe | grep -E "Topic:|Partition:|Leader:|Replicas:"
```

### Тестирование масштабирования (добавление брокера)

**Внимание:** Для добавления брокера необходимо сначала добавить его в `docker-compose.yml`.

```bash
# Проверка текущего количества брокеров
docker ps --filter "name=kafka-" | wc -l

# После добавления брокера в docker-compose.yml:
docker-compose up -d kafka-4

# Проверка нового брокера
docker exec kafka-4 kafka-broker-api-versions --bootstrap-server localhost:9092
```

### Тестирование удаления брокера (после ребалансировки)

```bash
# ВНИМАНИЕ: Перед удалением необходимо выполнить ребалансировку партиций!

# Остановка брокера
docker-compose stop kafka-3

# Проверка, что кластер работает без этого брокера
docker exec kafka-1 kafka-topics --bootstrap-server kafka-1:9092,kafka-2:9092 --list
```

### Автоматический тест

```bash
./scripts/test-cluster.sh
```

---

## Задача 4: Управление конфигурацией брокеров (Broker Config Management)

### Проверка текущей конфигурации брокера

```bash
# Конфигурация брокера 1
docker exec kafka-1 kafka-configs --bootstrap-server kafka-1:9092,kafka-2:9092,kafka-3:9092 --entity-type brokers --entity-name 1 --describe

# Конфигурация брокера 2
docker exec kafka-1 kafka-configs --bootstrap-server kafka-1:9092,kafka-2:9092,kafka-3:9092 --entity-type brokers --entity-name 2 --describe

# Конфигурация брокера 3
docker exec kafka-1 kafka-configs --bootstrap-server kafka-1:9092,kafka-2:9092,kafka-3:9092 --entity-type brokers --entity-name 3 --describe
```

### Применение новой конфигурации

```bash
# Измените kafka_broker_config в group_vars/all.yml
# Затем примените:
ansible-playbook playbooks/manage-config.yml

# Проверьте изменения:
docker exec kafka-1 kafka-configs --bootstrap-server kafka-1:9092,kafka-2:9092,kafka-3:9092 --entity-type brokers --entity-name 1 --describe
```

### Проверка бэкапов конфигурации

```bash
# Список бэкапов
ls -lh config_backups/

# Просмотр бэкапа
cat config_backups/broker-1-*.backup | head -20

# Просмотр версии конфигурации
cat config_backups/broker-1-version-*.yml
```

### Откат конфигурации

```bash
# Откат к предыдущей версии
ansible-playbook playbooks/rollback-config.yml

# Проверка отката
docker exec kafka-1 kafka-configs --bootstrap-server kafka-1:9092,kafka-2:9092,kafka-3:9092 --entity-type brokers --entity-name 1 --describe
```

### Автоматический тест

```bash
./scripts/test-config.sh
```

---

## Комплексная проверка всех задач

### Полное тестирование

```bash
# Запуск всех тестов
./scripts/test-all.sh
```

### Проверка через Ansible

```bash
# Проверка подключения
ansible all -m ping

# Проверка синтаксиса playbooks
ansible-playbook --syntax-check playbooks/site.yml
ansible-playbook --syntax-check playbooks/manage-topics.yml
ansible-playbook --syntax-check playbooks/manage-config.yml

# Dry-run (проверка без применения)
ansible-playbook --check playbooks/site.yml
```

### Проверка работы топиков

```bash
# Создание тестового сообщения
docker exec -it kafka-1 kafka-console-producer --bootstrap-server kafka-1:9092 --topic test-topic-1
# Введите несколько сообщений и нажмите Ctrl+D

# Чтение сообщений
docker exec -it kafka-1 kafka-console-consumer --bootstrap-server kafka-1:9092 --topic test-topic-1 --from-beginning
```

### Проверка репликации

```bash
# Проверка, что партиции реплицированы на все брокеры
docker exec kafka-1 kafka-topics --bootstrap-server kafka-1:9092,kafka-2:9092,kafka-3:9092 --describe --topic test-topic-1 | grep -E "Partition|Replicas"

# Должны быть видны реплики на разных брокерах (например: Replicas: 1,2,3)
```

---

## Дополнительные полезные команды

### Мониторинг кластера

```bash
# Статус всех контейнеров
docker-compose ps

# Логи брокера
docker-compose logs -f kafka-1

# Использование ресурсов
docker stats kafka-1 kafka-2 kafka-3
```

### Очистка и перезапуск

```bash
# Остановка кластера
docker-compose down

# Остановка с удалением данных
docker-compose down -v

# Перезапуск одного брокера
docker-compose restart kafka-1

# Перезапуск всего кластера
docker-compose restart
```

### Проверка здоровья кластера

```bash
# Healthcheck контейнеров
docker ps --filter "name=kafka-" --format "table {{.Names}}\t{{.Status}}"

# Проверка подключения к Zookeeper
docker exec kafka-zookeeper echo ruok | nc localhost 2181
# Должен вернуть: imok
```
