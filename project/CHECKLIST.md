# Чеклист проверки выполнения задач

## ✅ Задача 1: Управление топиками

### Проверка:
```bash
# 1. Запустите кластер
docker-compose up -d

# 2. Примените конфигурацию топиков
ansible-playbook playbooks/manage-topics.yml

# 3. Проверьте созданные топики
docker exec kafka-1 kafka-topics --bootstrap-server kafka-1:9092,kafka-2:9092,kafka-3:9092 --list

# 4. Проверьте детали топика
docker exec kafka-1 kafka-topics --bootstrap-server kafka-1:9092,kafka-2:9092,kafka-3:9092 --describe --topic test-topic-1

# 5. Запустите автоматический тест
./scripts/test-topics.sh
```

### Ожидаемый результат:
- ✓ Топики созданы согласно `group_vars/all.yml`
- ✓ Партиции и репликация настроены правильно
- ✓ Политики очистки применены

---

## ✅ Задача 2: Управление доступом (ACL/SASL)

### Проверка:
```bash
# 1. Примените конфигурацию ACL
ansible-playbook playbooks/manage-acl.yml

# 2. Проверьте вывод (должно быть предупреждение о SASL)
```

### Ожидаемый результат:
- ✓ Playbook выполняется без ошибок
- ✓ Выводится предупреждение о необходимости настройки SASL
- ✓ Структура для управления ACL готова

**Примечание:** Для полной функциональности требуется настройка Kafka с SASL.

---

## ✅ Задача 3: Масштабирование кластера

### Проверка:
```bash
# 1. Проверьте текущее состояние
docker ps --filter "name=kafka-"

# 2. Проверьте статус кластера
./scripts/test-cluster.sh

# 3. Проверьте метаданные кластера
docker exec kafka-1 kafka-broker-api-versions --bootstrap-server kafka-1:9092,kafka-2:9092,kafka-3:9092 | head -10
```

### Ожидаемый результат:
- ✓ 3 брокера запущены и работают
- ✓ Кластер доступен и отвечает
- ✓ Все брокеры видят друг друга

---

## ✅ Задача 4: Управление конфигурацией брокеров

### Проверка:
```bash
# 1. Примените конфигурацию
ansible-playbook playbooks/manage-config.yml

# 2. Проверьте конфигурацию брокера
docker exec kafka-1 kafka-configs --bootstrap-server kafka-1:9092,kafka-2:9092,kafka-3:9092 --entity-type brokers --entity-name 1 --describe

# 3. Проверьте бэкапы
ls -lh config_backups/

# 4. Запустите автоматический тест
./scripts/test-config.sh

# 5. Протестируйте откат (опционально)
ansible-playbook playbooks/rollback-config.yml
```

### Ожидаемый результат:
- ✓ Конфигурация применена к брокерам
- ✓ Созданы бэкапы конфигурации
- ✓ Версионирование работает
- ✓ Откат возможен

---

## Полная проверка всех задач

### Комплексный тест:
```bash
# 1. Запуск кластера
docker-compose up -d
sleep 30  # Ожидание запуска

# 2. Применение всех конфигураций
ansible-playbook playbooks/site.yml

# 3. Полное тестирование
./scripts/test-all.sh

# 4. Проверка работы топиков
docker exec -it kafka-1 kafka-console-producer --bootstrap-server kafka-1:9092 --topic test-topic-1
# Введите несколько сообщений, затем Ctrl+D

docker exec -it kafka-1 kafka-console-consumer --bootstrap-server kafka-1:9092 --topic test-topic-1 --from-beginning
# Должны быть видны отправленные сообщения
```

### Ожидаемый результат:
- ✓ Все playbooks выполняются успешно
- ✓ Топики созданы и работают
- ✓ Конфигурация применена
- ✓ Бэкапы созданы
- ✓ Кластер функционирует корректно

---

## Дополнительные проверки

### Проверка репликации:
```bash
docker exec kafka-1 kafka-topics --bootstrap-server kafka-1:9092,kafka-2:9092,kafka-3:9092 --describe --topic test-topic-1 | grep -E "Partition|Replicas"
# Должны быть видны реплики на разных брокерах
```

### Проверка отказоустойчивости:
```bash
# Остановите один брокер
docker-compose stop kafka-2

# Проверьте, что кластер продолжает работать
docker exec kafka-1 kafka-topics --bootstrap-server kafka-1:9092,kafka-3:9092 --list

# Запустите брокер обратно
docker-compose start kafka-2
```

### Проверка версионирования:
```bash
# Измените конфигурацию в group_vars/all.yml
# Примените изменения
ansible-playbook playbooks/manage-config.yml

# Проверьте, что создан новый бэкап
ls -lt config_backups/ | head -5
```

---

## Критерии успешного выполнения

- [x] Все 4 задачи реализованы
- [x] Playbooks выполняются без ошибок
- [x] Топики создаются и управляются через Ansible
- [x] Конфигурация брокеров версионируется
- [x] Бэкапы создаются автоматически
- [x] Скрипты тестирования работают
- [x] Документация полная и понятная
- [x] Все разворачивается в контейнерах
- [x] Можно применить на локальном компьютере

---

## Полезные команды для отладки

```bash
# Проверка синтаксиса Ansible
ansible-playbook --syntax-check playbooks/site.yml

# Dry-run (без применения изменений)
ansible-playbook --check playbooks/site.yml

# Подробный вывод
ansible-playbook -vvv playbooks/site.yml

# Проверка подключения
ansible all -m ping

# Логи контейнеров
docker-compose logs -f kafka-1
```
