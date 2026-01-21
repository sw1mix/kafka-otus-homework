#!/bin/bash
# Полный цикл тестирования всех 4 задач

set -e

echo "=========================================="
echo "  Полное тестирование всех задач"
echo "=========================================="
echo ""

# Цвета
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Проверка доступности кластера
echo -e "${BLUE}Проверка доступности кластера...${NC}"
if ! docker ps --filter "name=kafka-1" --format "{{.Names}}" | grep -q "kafka-1"; then
    echo "Ошибка: Кластер не запущен. Запустите: docker-compose up -d"
    exit 1
fi
echo -e "${GREEN}✓ Кластер доступен${NC}"
echo ""

# Задача 1: Управление топиками
echo -e "${YELLOW}=== Задача 1: Управление топиками ===${NC}"
./scripts/test-task1-topics.sh
echo ""

# Задача 2: Управление ACL
echo -e "${YELLOW}=== Задача 2: Управление ACL/SASL ===${NC}"
./scripts/test-task2-acl.sh
echo ""

# Задача 3: Масштабирование кластера
echo -e "${YELLOW}=== Задача 3: Масштабирование кластера ===${NC}"
./scripts/test-task3-scaling.sh
echo ""

# Задача 4: Управление конфигурацией
echo -e "${YELLOW}=== Задача 4: Управление конфигурацией брокеров ===${NC}"
./scripts/test-task4-config.sh
echo ""

# Итоговый отчет
echo "=========================================="
echo -e "${GREEN}  Все тесты завершены${NC}"
echo "=========================================="
echo ""
echo "Проверьте результаты выше. Для повторного тестирования отдельных задач:"
echo "  - Задача 1 (Топики): ./scripts/test-task1-topics.sh"
echo "  - Задача 2 (ACL): ./scripts/test-task2-acl.sh"
echo "  - Задача 3 (Масштабирование): ./scripts/test-task3-scaling.sh"
echo "  - Задача 4 (Конфигурация): ./scripts/test-task4-config.sh"
echo ""
