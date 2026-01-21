#!/bin/bash
# Полный цикл тестирования всех 4 задач

set +e  # Не останавливаться на ошибках, чтобы собрать все результаты

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

# Счетчики результатов
TASK1_OK=0
TASK2_OK=0
TASK3_OK=0
TASK4_OK=0

# Задача 1: Управление топиками
echo -e "${YELLOW}=== Задача 1: Управление топиками ===${NC}"
if ./scripts/test-task1-topics.sh; then
    TASK1_OK=1
    echo -e "${GREEN}✓ Задача 1: УСПЕШНО${NC}"
else
    echo -e "${RED}✗ Задача 1: ОШИБКИ${NC}"
fi
echo ""

# Задача 2: Управление ACL
echo -e "${YELLOW}=== Задача 2: Управление ACL/SASL ===${NC}"
if ./scripts/test-task2-acl.sh; then
    TASK2_OK=1
    echo -e "${GREEN}✓ Задача 2: УСПЕШНО${NC}"
else
    echo -e "${RED}✗ Задача 2: ОШИБКИ${NC}"
fi
echo ""

# Задача 3: Масштабирование кластера
echo -e "${YELLOW}=== Задача 3: Масштабирование кластера ===${NC}"
if ./scripts/test-task3-scaling.sh; then
    TASK3_OK=1
    echo -e "${GREEN}✓ Задача 3: УСПЕШНО${NC}"
else
    echo -e "${RED}✗ Задача 3: ОШИБКИ${NC}"
fi
echo ""

# Задача 4: Управление конфигурацией
echo -e "${YELLOW}=== Задача 4: Управление конфигурацией брокеров ===${NC}"
if ./scripts/test-task4-config.sh; then
    TASK4_OK=1
    echo -e "${GREEN}✓ Задача 4: УСПЕШНО${NC}"
else
    echo -e "${RED}✗ Задача 4: ОШИБКИ${NC}"
fi
echo ""

# Итоговый отчет
echo "=========================================="
TOTAL_OK=$((TASK1_OK + TASK2_OK + TASK3_OK + TASK4_OK))
if [ $TOTAL_OK -eq 4 ]; then
    echo -e "${GREEN}  ✅ ВСЕ ТЕСТЫ ПРОЙДЕНЫ УСПЕШНО!${NC}"
    echo -e "${GREEN}  Все 4 задачи работают корректно${NC}"
    EXIT_CODE=0
elif [ $TOTAL_OK -eq 0 ]; then
    echo -e "${RED}  ❌ ВСЕ ТЕСТЫ ПРОВАЛЕНЫ${NC}"
    EXIT_CODE=1
else
    echo -e "${YELLOW}  ⚠ ЧАСТИЧНО УСПЕШНО: $TOTAL_OK из 4 задач${NC}"
    echo -e "${YELLOW}  Задача 1 (Топики): $([ $TASK1_OK -eq 1 ] && echo '✓' || echo '✗')${NC}"
    echo -e "${YELLOW}  Задача 2 (ACL): $([ $TASK2_OK -eq 1 ] && echo '✓' || echo '✗')${NC}"
    echo -e "${YELLOW}  Задача 3 (Масштабирование): $([ $TASK3_OK -eq 1 ] && echo '✓' || echo '✗')${NC}"
    echo -e "${YELLOW}  Задача 4 (Конфигурация): $([ $TASK4_OK -eq 1 ] && echo '✓' || echo '✗')${NC}"
    EXIT_CODE=1
fi
echo "=========================================="
echo ""
echo "Для повторного тестирования отдельных задач:"
echo "  - Задача 1 (Топики): ./scripts/test-task1-topics.sh"
echo "  - Задача 2 (ACL): ./scripts/test-task2-acl.sh"
echo "  - Задача 3 (Масштабирование): ./scripts/test-task3-scaling.sh"
echo "  - Задача 4 (Конфигурация): ./scripts/test-task4-config.sh"
echo ""

exit $EXIT_CODE
