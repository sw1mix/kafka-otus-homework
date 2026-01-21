#!/bin/bash
# Тестирование Задачи 3: Масштабирование кластера (Cluster Scaling)

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Задача 3: Масштабирование кластера${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Проверка запущенных контейнеров
echo -e "${YELLOW}1. Проверка запущенных брокеров:${NC}"
BROKERS=$(docker ps --filter "name=kafka-" --format "{{.Names}}" | wc -l)
echo "Найдено брокеров: $BROKERS"
docker ps --filter "name=kafka-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

# Проверка состояния каждого брокера
echo -e "${YELLOW}2. Проверка состояния брокеров:${NC}"
for broker in kafka-1 kafka-2 kafka-3; do
    if docker ps --format "{{.Names}}" | grep -q "^${broker}$"; then
        echo -e "${GREEN}✓ $broker запущен${NC}"
        if docker exec "$broker" kafka-broker-api-versions --bootstrap-server localhost:9092 > /dev/null 2>&1; then
            echo -e "  ${GREEN}  API доступен${NC}"
        else
            echo -e "  ${RED}  API недоступен${NC}"
        fi
    else
        echo -e "${RED}✗ $broker не запущен${NC}"
    fi
done
echo ""

# Проверка подключения к Zookeeper
echo -e "${YELLOW}3. Проверка подключения к Zookeeper:${NC}"
if docker ps --format "{{.Names}}" | grep -q "^kafka-zookeeper$"; then
    echo -e "${GREEN}✓ Zookeeper запущен${NC}"
    if echo ruok | docker exec -i kafka-zookeeper nc localhost 2181 2>/dev/null | grep -q "imok"; then
        echo -e "  ${GREEN}  Zookeeper отвечает${NC}"
    else
        echo -e "  ${YELLOW}  Zookeeper не отвечает на ruok${NC}"
    fi
else
    echo -e "${RED}✗ Zookeeper не запущен${NC}"
fi
echo ""

# Информация о кластере
echo -e "${YELLOW}4. Информация о кластере:${NC}"
docker exec kafka-1 kafka-broker-api-versions --bootstrap-server kafka-1:9092,kafka-2:9092,kafka-3:9092 2>/dev/null | head -5 || echo "Метаданные недоступны"
echo ""

# Проверка распределения партиций
echo -e "${YELLOW}5. Проверка распределения партиций по брокерам:${NC}"
TOPICS=$(docker exec kafka-1 kafka-topics --bootstrap-server kafka-1:9092,kafka-2:9092,kafka-3:9092 --list 2>/dev/null | head -3)
if [ -n "$TOPICS" ]; then
    for topic in $TOPICS; do
        echo -e "${GREEN}Топик: $topic${NC}"
        docker exec kafka-1 kafka-topics --bootstrap-server kafka-1:9092,kafka-2:9092,kafka-3:9092 --describe --topic "$topic" 2>/dev/null | grep -E "Partition:|Leader:|Replicas:" | head -5
        echo ""
    done
else
    echo -e "${YELLOW}Топики не найдены${NC}"
fi

# Тест отказоустойчивости
echo -e "${YELLOW}6. Тест отказоустойчивости (опционально):${NC}"
echo "Для теста отказоустойчивости выполните:"
echo "  docker-compose stop kafka-2"
echo "  docker exec kafka-1 kafka-topics --bootstrap-server kafka-1:9092,kafka-3:9092 --list"
echo "  docker-compose start kafka-2"
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Тест Задачи 3 завершен${NC}"
echo -e "${GREEN}========================================${NC}"
