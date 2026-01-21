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
        
        # Проверяем, есть ли реальная конфигурация (не только null)
        if echo "$CONFIG" | grep -q "Dynamic configs for broker"; then
            if echo "$CONFIG" | grep -q "key=null"; then
                echo "  Динамическая конфигурация не применена"
                echo "  Используются значения из server.properties"
                echo "  Примечание: kafka-configs показывает только динамическую конфигурацию"
                echo "  Статическая конфигурация находится в config/kafka/server.properties"
            else
                echo "$CONFIG" | grep -v "key=null" | head -15
            fi
        else
            echo "  Не удалось получить конфигурацию"
        fi
        echo ""
    fi
done

# Проверка бэкапов
echo -e "${YELLOW}4. Проверка бэкапов конфигурации:${NC}"
# Бэкапы могут быть в разных местах в зависимости от того, откуда запущен playbook
BACKUP_DIRS=("./config_backups" "./playbooks/config_backups" "$(dirname "$0")/../config_backups" "$(dirname "$0")/../playbooks/config_backups")
BACKUP_DIR=""
for dir in "${BACKUP_DIRS[@]}"; do
    if [ -d "$dir" ] && [ "$(find "$dir" -name "*.backup" 2>/dev/null | wc -l)" -gt 0 ]; then
        BACKUP_DIR="$dir"
        break
    fi
done

if [ -z "$BACKUP_DIR" ]; then
    # Проверяем все возможные места
    BACKUP_DIR="./config_backups"
fi
# Ищем бэкапы во всех возможных местах
ALL_BACKUPS=$(find . -name "*.backup" -type f 2>/dev/null | head -10)
ALL_VERSIONS=$(find . -name "*version*.yml" -type f 2>/dev/null | head -10)

if [ -n "$ALL_BACKUPS" ]; then
    BACKUP_COUNT=$(echo "$ALL_BACKUPS" | wc -l)
    echo -e "${GREEN}✓ Найдено бэкапов: $BACKUP_COUNT${NC}"
    echo "  Расположение:"
    echo "$ALL_BACKUPS" | head -5 | sed 's|^\./|    |'
    
    if [ -n "$ALL_VERSIONS" ]; then
        VERSION_COUNT=$(echo "$ALL_VERSIONS" | wc -l)
        echo ""
        echo -e "${GREEN}Версии конфигурации: $VERSION_COUNT${NC}"
        echo "$ALL_VERSIONS" | head -3 | sed 's|^\./|    |'
    fi
else
    echo -e "${YELLOW}⚠ Бэкапы не найдены${NC}"
    echo "  Бэкапы создаются при первом изменении конфигурации"
    echo "  Проверьте директории: ./config_backups или ./playbooks/config_backups"
fi
echo ""

# Проверка переменных конфигурации
echo -e "${YELLOW}5. Проверка переменных конфигурации (kafka_broker_config):${NC}"
if grep -q "kafka_broker_config:" group_vars/all.yml; then
    echo -e "${GREEN}✓ Переменные конфигурации определены:${NC}"
    grep -A 10 "kafka_broker_config:" group_vars/all.yml | head -15
    echo ""
    echo -e "${YELLOW}Примечание:${NC}"
    echo "  Некоторые параметры (num.network.threads, num.io.threads, socket.*)"
    echo "  требуют перезапуска брокера и не могут быть изменены динамически."
    echo "  Только параметры типа log.retention.* могут быть изменены через kafka-configs."
else
    echo -e "${YELLOW}⚠ Переменные конфигурации не найдены${NC}"
fi
echo ""

# Тест отката (информация)
echo -e "${YELLOW}6. Информация об откате конфигурации:${NC}"
BACKUP_COUNT=$(find . -name "*.backup" -type f 2>/dev/null | wc -l)
if [ "$BACKUP_COUNT" -gt 0 ]; then
    echo -e "${GREEN}✓ Бэкапы доступны для отката ($BACKUP_COUNT файлов)${NC}"
    echo "Для отката выполните:"
    echo "  ./scripts/run-ansible.sh playbooks/rollback-config.yml"
else
    echo -e "${YELLOW}⚠ Бэкапы не найдены, откат недоступен${NC}"
    echo "  Бэкапы создаются автоматически при изменении конфигурации"
fi
echo ""

# Дополнительная проверка: показываем последние изменения конфигурации
echo -e "${YELLOW}7. Последние изменения конфигурации:${NC}"
LATEST_VERSION=$(find . -name "*version*.yml" -type f 2>/dev/null | head -1)
if [ -n "$LATEST_VERSION" ]; then
    echo -e "${GREEN}Последняя версия: $(basename "$LATEST_VERSION")${NC}"
    echo "  Путь: $LATEST_VERSION"
    echo "Содержимое:"
    head -10 "$LATEST_VERSION" | sed 's/^/  /'
else
    echo "  Версии конфигурации не найдены"
fi
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Тест Задачи 4 завершен${NC}"
echo -e "${GREEN}========================================${NC}"
