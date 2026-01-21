#!/bin/bash
# Скрипт для тестирования управления топиками

set -e

echo "=== Тестирование управления топиками ==="
echo ""

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Проверка доступности Kafka
echo -e "${YELLOW}1. Проверка доступности Kafka кластера...${NC}"
if docker exec kafka-1 kafka-topics --bootstrap-server localhost:9092 --list > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Kafka доступен${NC}"
else
    echo -e "${RED}✗ Kafka недоступен. Убедитесь, что контейнеры запущены.${NC}"
    exit 1
fi

# Получение списка топиков
echo -e "${YELLOW}2. Получение списка существующих топиков...${NC}"
docker exec kafka-1 kafka-topics --bootstrap-server kafka-1:9092,kafka-2:9092,kafka-3:9092 --list
echo ""

# Детальная информация о топиках
echo -e "${YELLOW}3. Детальная информация о топиках:${NC}"
for topic in $(docker exec kafka-1 kafka-topics --bootstrap-server kafka-1:9092,kafka-2:9092,kafka-3:9092 --list); do
    echo -e "${GREEN}Топик: $topic${NC}"
    docker exec kafka-1 kafka-topics --bootstrap-server kafka-1:9092,kafka-2:9092,kafka-3:9092 --describe --topic "$topic"
    echo ""
done

# Проверка конфигурации топиков
echo -e "${YELLOW}4. Проверка конфигурации топиков:${NC}"
for topic in test-topic-1 test-topic-2 events; do
    if docker exec kafka-1 kafka-topics --bootstrap-server kafka-1:9092,kafka-2:9092,kafka-3:9092 --list | grep -q "^${topic}$"; then
        echo -e "${GREEN}Топик $topic существует${NC}"
        docker exec kafka-1 kafka-configs --bootstrap-server kafka-1:9092,kafka-2:9092,kafka-3:9092 --entity-type topics --entity-name "$topic" --describe
        echo ""
    else
        echo -e "${RED}Топик $topic не найден${NC}"
    fi
done

# Проверка партиций
echo -e "${YELLOW}5. Проверка распределения партиций:${NC}"
docker exec kafka-1 kafka-topics --bootstrap-server kafka-1:9092,kafka-2:9092,kafka-3:9092 --describe | grep -E "Topic:|Partition:"
echo ""

echo -e "${GREEN}=== Тестирование завершено ===${NC}"
