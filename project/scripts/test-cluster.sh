#!/bin/bash
# Скрипт для тестирования состояния кластера

set -e

echo "=== Тестирование состояния кластера Kafka ==="
echo ""

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Проверка запущенных контейнеров
echo -e "${YELLOW}1. Проверка запущенных контейнеров:${NC}"
docker ps --filter "name=kafka-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

# Проверка состояния брокеров
echo -e "${YELLOW}2. Проверка состояния брокеров:${NC}"
for broker in kafka-1 kafka-2 kafka-3; do
    if docker ps --format "{{.Names}}" | grep -q "^${broker}$"; then
        echo -e "${GREEN}✓ $broker запущен${NC}"
        docker exec "$broker" kafka-broker-api-versions --bootstrap-server localhost:9092 > /dev/null 2>&1 && \
            echo -e "  ${GREEN}  API доступен${NC}" || \
            echo -e "  ${RED}  API недоступен${NC}"
    else
        echo -e "${RED}✗ $broker не запущен${NC}"
    fi
done
echo ""

# Проверка подключения к Zookeeper
echo -e "${YELLOW}3. Проверка подключения к Zookeeper:${NC}"
if docker ps --format "{{.Names}}" | grep -q "^kafka-zookeeper$"; then
    echo -e "${GREEN}✓ Zookeeper запущен${NC}"
    docker exec kafka-zookeeper echo ruok | nc localhost 2181 && \
        echo -e "  ${GREEN}  Zookeeper отвечает${NC}" || \
        echo -e "  ${RED}  Zookeeper не отвечает${NC}"
else
    echo -e "${RED}✗ Zookeeper не запущен${NC}"
fi
echo ""

# Информация о кластере
echo -e "${YELLOW}4. Информация о кластере:${NC}"
docker exec kafka-1 kafka-broker-api-versions --bootstrap-server kafka-1:9092,kafka-2:9092,kafka-3:9092 | head -5
echo ""

# Проверка метаданных
echo -e "${YELLOW}5. Метаданные кластера:${NC}"
docker exec kafka-1 kafka-metadata-quorum --bootstrap-server kafka-1:9092,kafka-2:9092,kafka-3:9092 describe --status 2>/dev/null || \
    echo "Метаданные недоступны (возможно, используется Zookeeper)"
echo ""

echo -e "${GREEN}=== Тестирование завершено ===${NC}"
