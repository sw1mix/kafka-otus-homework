#!/bin/bash
# Тестирование Задачи 4: Управление конфигурацией брокеров (Broker Config Management)

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Задача 4: Управление конфигурацией${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Проверка доступности Kafka
echo -e "${YELLOW}1. Проверка доступности Kafka...${NC}"
if ! docker exec kafka-1 kafka-topics --bootstrap-server localhost:9092 --list > /dev/null 2>&1; then
    echo -e "${RED}✗ Kafka недоступен. Запустите: docker-compose up -d${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Kafka доступен${NC}"
echo ""

# Применение конфигурации
echo -e "${YELLOW}2. Применение конфигурации брокеров через Ansible...${NC}"
cd "$(dirname "$0")/.."
if ./scripts/run-ansible.sh playbooks/manage-config.yml; then
    echo -e "${GREEN}✓ Конфигурация применена${NC}"
else
    echo -e "${RED}✗ Ошибка при применении конфигурации${NC}"
    exit 1
fi
echo ""

# Проверка конфигурации каждого брокера
echo -e "${YELLOW}3. Проверка конфигурации брокеров:${NC}"
for broker_id in 1 2 3; do
    broker_name="kafka-${broker_id}"
    if docker ps --format "{{.Names}}" | grep -q "^${broker_name}$"; then
        echo -e "${GREEN}Брокер $broker_id:${NC}"
        CONFIG=$(docker exec "$broker_name" kafka-configs \
            --bootstrap-server kafka-1:9092,kafka-2:9092,kafka-3:9092 \
            --entity-type brokers \
            --entity-name "$broker_id" \
            --describe 2>/dev/null)
        if [ -n "$CONFIG" ]; then
            echo "$CONFIG" | head -10
        else
            echo "  Конфигурация по умолчанию"
        fi
        echo ""
    fi
done

# Проверка бэкапов
echo -e "${YELLOW}4. Проверка бэкапов конфигурации:${NC}"
if [ -d "./config_backups" ] && [ "$(ls -A ./config_backups/*.backup 2>/dev/null)" ]; then
    echo -e "${GREEN}✓ Найдены бэкапы:${NC}"
    ls -lh ./config_backups/*.backup 2>/dev/null | tail -5
    echo ""
    echo -e "${GREEN}Версии конфигурации:${NC}"
    ls -lh ./config_backups/*version*.yml 2>/dev/null | tail -3 || echo "  Версии не найдены"
else
    echo -e "${YELLOW}⚠ Директория бэкапов пуста или не найдена${NC}"
fi
echo ""

# Проверка переменных конфигурации
echo -e "${YELLOW}5. Проверка переменных конфигурации (kafka_broker_config):${NC}"
if grep -q "kafka_broker_config:" group_vars/all.yml; then
    echo -e "${GREEN}✓ Переменные конфигурации определены:${NC}"
    grep -A 10 "kafka_broker_config:" group_vars/all.yml | head -15
else
    echo -e "${YELLOW}⚠ Переменные конфигурации не найдены${NC}"
fi
echo ""

# Тест отката (информация)
echo -e "${YELLOW}6. Информация об откате конфигурации:${NC}"
if [ -d "./config_backups" ] && [ "$(ls -A ./config_backups/*.backup 2>/dev/null)" ]; then
    echo -e "${GREEN}✓ Бэкапы доступны для отката${NC}"
    echo "Для отката выполните:"
    echo "  ./scripts/run-ansible.sh playbooks/rollback-config.yml"
else
    echo -e "${YELLOW}⚠ Бэкапы не найдены, откат недоступен${NC}"
fi
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Тест Задачи 4 завершен${NC}"
echo -e "${GREEN}========================================${NC}"
