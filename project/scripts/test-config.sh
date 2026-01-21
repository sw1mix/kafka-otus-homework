#!/bin/bash
# Скрипт для тестирования конфигурации брокеров

set -e

echo "=== Тестирование конфигурации брокеров ==="
echo ""

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Проверка конфигурации каждого брокера
echo -e "${YELLOW}1. Проверка конфигурации брокеров:${NC}"
for broker_id in 1 2 3; do
    broker_name="kafka-${broker_id}"
    if docker ps --format "{{.Names}}" | grep -q "^${broker_name}$"; then
        echo -e "${GREEN}Брокер $broker_id:${NC}"
        docker exec "$broker_name" kafka-configs \
            --bootstrap-server kafka-1:9092,kafka-2:9092,kafka-3:9092 \
            --entity-type brokers \
            --entity-name "$broker_id" \
            --describe 2>/dev/null || echo "  Конфигурация по умолчанию"
        echo ""
    fi
done

# Проверка бэкапов конфигурации
echo -e "${YELLOW}2. Проверка бэкапов конфигурации:${NC}"
if [ -d "./config_backups" ]; then
    echo -e "${GREEN}Найдены бэкапы:${NC}"
    ls -lh ./config_backups/ | tail -n +2
else
    echo -e "${YELLOW}Директория бэкапов не найдена${NC}"
fi
echo ""

# Проверка версий конфигурации
echo -e "${YELLOW}3. Проверка версий конфигурации:${NC}"
if [ -d "./config_backups" ]; then
    for version_file in ./config_backups/*version*.yml; do
        if [ -f "$version_file" ]; then
            echo -e "${GREEN}Версия: $(basename $version_file)${NC}"
            cat "$version_file" | head -5
            echo ""
        fi
    done
fi

echo -e "${GREEN}=== Тестирование завершено ===${NC}"
