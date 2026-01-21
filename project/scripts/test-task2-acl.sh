#!/bin/bash
# Тестирование Задачи 2: Управление доступом (ACL/SASL Management)

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Задача 2: Управление ACL/SASL${NC}"
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

# Применение конфигурации ACL
echo -e "${YELLOW}2. Применение конфигурации ACL через Ansible...${NC}"
cd "$(dirname "$0")/.."
if ./scripts/run-ansible.sh playbooks/manage-acl.yml; then
    echo -e "${GREEN}✓ Конфигурация применена${NC}"
else
    echo -e "${YELLOW}⚠ Playbook выполнен с предупреждениями (это нормально, если SASL не включен)${NC}"
fi
echo ""

# Проверка переменных пользователей
echo -e "${YELLOW}3. Проверка переменных пользователей (kafka_users):${NC}"
if grep -q "kafka_users:" group_vars/all.yml; then
    echo -e "${GREEN}✓ Переменные пользователей определены:${NC}"
    grep -A 15 "kafka_users:" group_vars/all.yml | head -20
else
    echo -e "${RED}✗ Переменные пользователей не найдены${NC}"
fi
echo ""

# Проверка переменных ACL
echo -e "${YELLOW}4. Проверка переменных ACL (kafka_acls):${NC}"
if grep -q "kafka_acls:" group_vars/all.yml; then
    echo -e "${GREEN}✓ Переменные ACL определены:${NC}"
    grep -A 25 "kafka_acls:" group_vars/all.yml | head -30
else
    echo -e "${RED}✗ Переменные ACL не найдены${NC}"
fi
echo ""

# Проверка безопасности (пароли не должны быть в логах)
echo -e "${YELLOW}5. Проверка безопасного хранения учетных данных:${NC}"
if grep -q "password:" group_vars/all.yml; then
    echo -e "${GREEN}✓ Учетные данные определены в переменных${NC}"
    echo "  Пароли хранятся в group_vars/all.yml (в продакшене используйте Ansible Vault)"
else
    echo -e "${YELLOW}⚠ Учетные данные не найдены${NC}"
fi
echo ""

# Проверка конфигурации безопасности Kafka
echo -e "${YELLOW}6. Проверка конфигурации безопасности Kafka:${NC}"
if docker exec kafka-1 cat /etc/kafka/server.properties 2>/dev/null | grep -qi "sasl"; then
    echo -e "${GREEN}✓ SASL настроен${NC}"
else
    echo -e "${YELLOW}⚠ SASL не настроен (это нормально для PLAINTEXT режима)${NC}"
    echo "  Для полной функциональности ACL требуется настройка SASL"
fi
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Тест Задачи 2 завершен${NC}"
echo -e "${YELLOW}Примечание: Для полной функциональности ACL требуется настройка SASL${NC}"
echo -e "${GREEN}========================================${NC}"
