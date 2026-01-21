#!/bin/bash
# Тестирование Задачи 1: Управление топиками (Topic Management)

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Задача 1: Управление топиками${NC}"
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

# Применение конфигурации топиков
echo -e "${YELLOW}2. Применение конфигурации топиков через Ansible...${NC}"
cd "$(dirname "$0")/.."
if ./scripts/run-ansible.sh playbooks/manage-topics.yml; then
    echo -e "${GREEN}✓ Конфигурация применена${NC}"
else
    echo -e "${RED}✗ Ошибка при применении конфигурации${NC}"
    exit 1
fi
echo ""

# Список топиков
echo -e "${YELLOW}3. Список всех топиков:${NC}"
docker exec kafka-1 kafka-topics --bootstrap-server kafka-1:9092,kafka-2:9092,kafka-3:9092 --list
echo ""

# Детальная информация о топиках
echo -e "${YELLOW}4. Детальная информация о топиках:${NC}"
for topic in $(docker exec kafka-1 kafka-topics --bootstrap-server kafka-1:9092,kafka-2:9092,kafka-3:9092 --list); do
    echo -e "${GREEN}Топик: $topic${NC}"
    docker exec kafka-1 kafka-topics --bootstrap-server kafka-1:9092,kafka-2:9092,kafka-3:9092 --describe --topic "$topic" | head -5
    echo ""
done

# Проверка конфигурации топиков
echo -e "${YELLOW}5. Проверка конфигурации топиков:${NC}"
for topic in test-topic-1 test-topic-2 events; do
    if docker exec kafka-1 kafka-topics --bootstrap-server kafka-1:9092,kafka-2:9092,kafka-3:9092 --list | grep -q "^${topic}$"; then
        echo -e "${GREEN}Топик $topic:${NC}"
        docker exec kafka-1 kafka-configs --bootstrap-server kafka-1:9092,kafka-2:9092,kafka-3:9092 --entity-type topics --entity-name "$topic" --describe 2>/dev/null | grep -E "retention|cleanup|compression" || echo "  Конфигурация по умолчанию"
        echo ""
    fi
done

# Проверка репликации
echo -e "${YELLOW}6. Проверка репликации партиций:${NC}"
docker exec kafka-1 kafka-topics --bootstrap-server kafka-1:9092,kafka-2:9092,kafka-3:9092 --describe | grep -E "Topic:|Partition:|Replicas:" | head -20
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Тест Задачи 1 завершен${NC}"
echo -e "${GREEN}========================================${NC}"
