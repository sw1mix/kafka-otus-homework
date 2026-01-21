# Быстрый старт

## Шаг 1: Запуск кластера

```bash
cd project
docker-compose up -d
```

Подождите 30-60 секунд, пока кластер запустится. Проверьте статус:

```bash
docker-compose ps
```

## Шаг 2: Применение конфигурации

```bash
# Настройка окружения (установит Ansible если нужно)
./scripts/setup.sh

# Если Ansible установлен в venv, активируйте его:
source venv/bin/activate

# Применение всех конфигураций
ansible-playbook playbooks/site.yml

# Или используйте обертку (автоматически выберет правильный Ansible):
./scripts/run-ansible.sh playbooks/site.yml
```

## Шаг 3: Проверка

```bash
# Запуск всех тестов
./scripts/test-all.sh

# Или отдельные проверки:
./scripts/test-cluster.sh    # Проверка кластера
./scripts/test-topics.sh     # Проверка топиков
./scripts/test-config.sh     # Проверка конфигурации
```

## Примеры использования

### Создание топика

Измените `group_vars/all.yml`:

```yaml
kafka_topics:
  - name: "my-new-topic"
    partitions: 6
    replication_factor: 3
```

Примените:

```bash
ansible-playbook playbooks/manage-topics.yml
```

### Изменение конфигурации брокера

Измените `group_vars/all.yml`:

```yaml
kafka_broker_config:
  log.retention.hours: "336"  # 14 дней
```

Примените:

```bash
ansible-playbook playbooks/manage-config.yml
```

### Откат конфигурации

```bash
ansible-playbook playbooks/rollback-config.yml
```

## Остановка кластера

```bash
docker-compose down
```

Для полного удаления данных:

```bash
docker-compose down -v
```
