#!/bin/bash
# Скрипт для настройки PostgreSQL и создания тестовой таблицы

echo "Настройка PostgreSQL для Debezium CDC..."

# Ждем готовности PostgreSQL
echo "Ожидание готовности PostgreSQL..."
until docker-compose exec -T postgres pg_isready -U postgres > /dev/null 2>&1; do
    echo "PostgreSQL еще не готов, ждем..."
    sleep 2
done

echo "PostgreSQL готов!"

# Создаем таблицу и настраиваем репликацию
echo "Создание тестовой таблицы..."
docker-compose exec -T postgres psql -U postgres -d testdb < create_table.sql

# Проверяем, что таблица создана
echo "Проверка созданной таблицы:"
docker-compose exec -T postgres psql -U postgres -d testdb -c "\d test_table"

echo ""
echo "✓ PostgreSQL настроен для Debezium CDC"
echo "✓ Таблица test_table создана"
echo "✓ Логическая репликация включена"
