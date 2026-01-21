# Краткое описание проекта

## Что реализовано

### ✅ Задача 1: Управление топиками (Topic Management)
- Декларативное создание топиков через переменные Ansible
- Изменение конфигурации существующих топиков
- Увеличение количества партиций
- Удаление топиков
- Контроль параметров: репликация, партиции, политики очистки

**Файлы:**
- `roles/kafka_topics/tasks/main.yml`
- `playbooks/manage-topics.yml`

### ✅ Задача 2: Управление доступом (ACL/SASL Management)
- Автоматизация создания пользователей SASL/SCRAM
- Управление ACL правилами через переменные
- Централизованное хранение учетных данных в переменных

**Файлы:**
- `roles/kafka_acl/tasks/main.yml`
- `playbooks/manage-acl.yml`

**Примечание:** Требует настройки Kafka с SASL для полной функциональности.

### ✅ Задача 3: Масштабирование кластера (Cluster Scaling)
- Добавление новых брокеров
- Удаление брокеров (с предупреждением о ребалансировке)
- Автоматическая проверка готовности брокеров
- Отслеживание состояния кластера

**Файлы:**
- `roles/kafka_scaling/tasks/main.yml`
- `roles/kafka_scaling/tasks/rebalance.yml`
- `playbooks/scale-cluster.yml`

### ✅ Задача 4: Управление конфигурацией брокеров (Broker Config Management)
- Версионирование конфигурации
- Автоматическое создание бэкапов
- Безопасное развертывание изменений
- Откат конфигурации к предыдущим версиям

**Файлы:**
- `roles/kafka_config/tasks/main.yml`
- `roles/kafka_config/tasks/rollback.yml`
- `playbooks/manage-config.yml`
- `playbooks/rollback-config.yml`

## Структура проекта

```
project/
├── docker-compose.yml          # 3 брокера Kafka + Zookeeper
├── ansible.cfg                 # Конфигурация Ansible
├── inventory/hosts.yml         # Inventory для Ansible
├── group_vars/all.yml         # Все переменные конфигурации
├── roles/                      # 4 роли Ansible
│   ├── kafka_topics/
│   ├── kafka_acl/
│   ├── kafka_scaling/
│   └── kafka_config/
├── playbooks/                  # 6 playbooks
│   ├── site.yml               # Главный playbook
│   ├── manage-topics.yml
│   ├── manage-acl.yml
│   ├── scale-cluster.yml
│   ├── manage-config.yml
│   └── rollback-config.yml
├── scripts/                    # Скрипты тестирования
│   ├── setup.sh
│   ├── test-all.sh
│   ├── test-cluster.sh
│   ├── test-topics.sh
│   └── test-config.sh
└── config/                     # Конфигурационные файлы
    └── kafka/server.properties
```

## Быстрый старт

```bash
# 1. Запуск кластера
cd project
docker-compose up -d

# 2. Применение конфигурации
ansible-playbook playbooks/site.yml

# 3. Тестирование
./scripts/test-all.sh
```

## Документация

- `README.md` - Полная документация проекта
- `QUICKSTART.md` - Быстрый старт
- `TEST_COMMANDS.md` - Команды для проверки всех задач

## Особенности

1. **Контейнеризация:** Все разворачивается в Docker контейнерах
2. **Декларативность:** Вся конфигурация через переменные Ansible
3. **Версионирование:** Автоматические бэкапы конфигурации
4. **Тестирование:** Готовые скрипты для проверки функционала
5. **Масштабируемость:** Поддержка добавления/удаления брокеров

## Требования

- Docker и Docker Compose
- Ansible 2.9+
- Python 3.6+

## Примеры использования

### Создание топика
```bash
# Изменить group_vars/all.yml, затем:
ansible-playbook playbooks/manage-topics.yml
```

### Изменение конфигурации брокера
```bash
# Изменить group_vars/all.yml, затем:
ansible-playbook playbooks/manage-config.yml
```

### Откат конфигурации
```bash
ansible-playbook playbooks/rollback-config.yml
```

### Масштабирование
```bash
ansible-playbook playbooks/scale-cluster.yml -e "kafka_target_brokers=['1','2','3','4']"
```
