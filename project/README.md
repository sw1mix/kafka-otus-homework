# Kafka Infrastructure as Code с Ansible

Проект для управления Apache Kafka кластером через Ansible Playbooks с поддержкой декларативного управления топиками, ACL, масштабирования и конфигурацией брокеров.

## Структура проекта

```
project/
├── docker-compose.yml          # Docker Compose для развертывания Kafka и Zookeeper
├── ansible.cfg                  # Конфигурация Ansible
├── inventory/                  # Inventory файлы
│   └── hosts.yml
├── group_vars/                  # Переменные Ansible
│   └── all.yml
├── roles/                       # Ansible роли
│   ├── kafka_topics/           # Управление топиками
│   ├── kafka_acl/              # Управление ACL/SASL
│   ├── kafka_scaling/          # Масштабирование кластера
│   └── kafka_config/           # Управление конфигурацией
├── playbooks/                  # Ansible playbooks
│   ├── site.yml                # Главный playbook
│   ├── manage-topics.yml       # Управление топиками
│   ├── manage-acl.yml          # Управление ACL
│   ├── scale-cluster.yml       # Масштабирование
│   ├── manage-config.yml       # Управление конфигурацией
│   └── rollback-config.yml     # Откат конфигурации
├── config/                     # Конфигурационные файлы
│   └── kafka/
│       └── server.properties
└── scripts/                     # Скрипты для тестирования
    ├── setup.sh
    ├── test-all.sh
    ├── test-cluster.sh
    ├── test-topics.sh
    └── test-config.sh
```

## Требования

- Docker и Docker Compose
- Ansible 2.9+ (будет установлен автоматически при запуске `setup.sh`)
- Python 3.6+ с модулем venv (для виртуального окружения)
- Доступ к интернету для загрузки образов Docker

### Установка зависимостей

Скрипт `setup.sh` автоматически установит Ansible одним из способов:
1. Через `apt` (если доступен)
2. В виртуальное окружение Python (если apt недоступен)

Если используется виртуальное окружение, активируйте его перед использованием:
```bash
source venv/bin/activate
```

Или используйте обертку `scripts/run-ansible.sh`:
```bash
./scripts/run-ansible.sh playbooks/site.yml
```

## Быстрый старт

### 1. Настройка окружения

```bash
cd project
./scripts/setup.sh
```

### 2. Запуск кластера Kafka

```bash
docker-compose up -d
```

Ожидание готовности кластера (около 30-60 секунд):

```bash
docker-compose ps
```

### 3. Применение конфигурации через Ansible

```bash
# Полное развертывание
ansible-playbook playbooks/site.yml

# Или отдельные компоненты:
ansible-playbook playbooks/manage-topics.yml
ansible-playbook playbooks/manage-config.yml
```

### 4. Тестирование

```bash
# Полное тестирование
./scripts/test-all.sh

# Или отдельные тесты:
./scripts/test-cluster.sh
./scripts/test-topics.sh
./scripts/test-config.sh
```

## Функционал

### 1. Управление топиками (Topic Management)

Декларативное создание, изменение и удаление топиков через переменные Ansible.

**Использование:**

```bash
ansible-playbook playbooks/manage-topics.yml
```

**Конфигурация в `group_vars/all.yml`:**

```yaml
kafka_topics:
  - name: "my-topic"
    partitions: 6
    replication_factor: 3
    config:
      retention.ms: "604800000"  # 7 дней
      cleanup.policy: "delete"
      compression.type: "snappy"
      min.insync.replicas: "2"
```

**Проверка:**

```bash
# Список топиков
docker exec kafka-1 kafka-topics --bootstrap-server kafka-1:9092,kafka-2:9092,kafka-3:9092 --list

# Детальная информация
docker exec kafka-1 kafka-topics --bootstrap-server kafka-1:9092,kafka-2:9092,kafka-3:9092 --describe --topic my-topic
```

### 2. Управление доступом (ACL/SASL Management)

Автоматизация управления пользователями (SASL/SCRAM) и распределением прав доступа (ACL).

**Использование:**

```bash
ansible-playbook playbooks/manage-acl.yml
```

**Конфигурация в `group_vars/all.yml`:**

```yaml
kafka_users:
  - username: "admin"
    password: "admin-secret-password"
    mechanism: "SCRAM-SHA-512"

kafka_acls:
  - principal: "User:admin"
    resource_type: "Topic"
    resource_name: "*"
    operation: "All"
    permission: "Allow"
```

**Примечание:** Для работы ACL/SASL необходимо настроить Kafka с включенным SASL. В текущей конфигурации используется PLAINTEXT.

### 3. Масштабирование кластера (Cluster Scaling)

Добавление или удаление брокеров с автоматическим обновлением конфигурации.

**Добавление брокера:**

```bash
# Добавить 4-й брокер (требуется обновить docker-compose.yml)
ansible-playbook playbooks/scale-cluster.yml -e "kafka_target_brokers=['1','2','3','4']"
```

**Удаление брокера:**

```bash
# Удалить 3-й брокер (после ребалансировки)
ansible-playbook playbooks/scale-cluster.yml \
  -e "kafka_target_brokers=['1','2']" \
  -e "kafka_force_remove_brokers=true"
```

**Проверка:**

```bash
docker ps --filter "name=kafka-"
```

### 4. Управление конфигурацией брокеров (Broker Config Management)

Версионирование и безопасное развертывание изменений в настройках брокеров.

**Применение конфигурации:**

```bash
ansible-playbook playbooks/manage-config.yml
```

**Конфигурация в `group_vars/all.yml`:**

```yaml
kafka_broker_config:
  log.retention.hours: "168"
  log.segment.bytes: "1073741824"
  num.network.threads: "8"
  num.io.threads: "8"
```

**Откат конфигурации:**

```bash
ansible-playbook playbooks/rollback-config.yml
```

**Проверка:**

```bash
# Текущая конфигурация брокера
docker exec kafka-1 kafka-configs \
  --bootstrap-server kafka-1:9092,kafka-2:9092,kafka-3:9092 \
  --entity-type brokers \
  --entity-name 1 \
  --describe
```

## Полезные команды

### Управление кластером

```bash
# Запуск
docker-compose up -d

# Остановка
docker-compose down

# Просмотр логов
docker-compose logs -f kafka-1

# Перезапуск брокера
docker-compose restart kafka-1
```

### Работа с топиками

```bash
# Создание топика вручную
docker exec kafka-1 kafka-topics \
  --bootstrap-server kafka-1:9092,kafka-2:9092,kafka-3:9092 \
  --create \
  --topic test-topic \
  --partitions 3 \
  --replication-factor 3

# Отправка сообщений
docker exec -it kafka-1 kafka-console-producer \
  --bootstrap-server kafka-1:9092 \
  --topic test-topic

# Чтение сообщений
docker exec -it kafka-1 kafka-console-consumer \
  --bootstrap-server kafka-1:9092 \
  --topic test-topic \
  --from-beginning
```

### Мониторинг

```bash
# Статус кластера
docker exec kafka-1 kafka-broker-api-versions \
  --bootstrap-server kafka-1:9092,kafka-2:9092,kafka-3:9092

# Информация о потребителях
docker exec kafka-1 kafka-consumer-groups \
  --bootstrap-server kafka-1:9092,kafka-2:9092,kafka-3:9092 \
  --list
```

## Переменные Ansible

Основные переменные находятся в `group_vars/all.yml`. Вы можете переопределить их:

- Через файл `host_vars/` для конкретных хостов
- Через `-e` при запуске playbook
- Через отдельный файл переменных: `ansible-playbook playbooks/site.yml -e @vars/custom.yml`

## Бэкапы конфигурации

Бэкапы конфигурации сохраняются в `./config_backups/` с версионированием. Каждое изменение конфигурации создает новый бэкап с меткой времени.

## Troubleshooting

### Kafka недоступен

```bash
# Проверка статуса контейнеров
docker-compose ps

# Проверка логов
docker-compose logs kafka-1

# Проверка подключения
docker exec kafka-1 kafka-topics --bootstrap-server localhost:9092 --list
```

### Проблемы с Ansible

```bash
# Проверка подключения
ansible all -m ping

# Проверка синтаксиса playbook
ansible-playbook --syntax-check playbooks/site.yml

# Запуск в режиме отладки
ansible-playbook -vvv playbooks/site.yml
```

### Очистка данных

```bash
# Остановка и удаление контейнеров с данными
docker-compose down -v

# Удаление только данных
docker volume rm project_kafka-1-data project_kafka-2-data project_kafka-3-data
```

## Лицензия

Проект создан в учебных целях.

## Автор

Ilya Dyachenko
