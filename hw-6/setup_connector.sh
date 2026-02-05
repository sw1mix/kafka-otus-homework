#!/bin/bash
# Скрипт для создания Debezium PostgreSQL Source Connector

echo "Создание Debezium PostgreSQL Source Connector..."

# Ждем готовности Kafka Connect
echo "Ожидание готовности Kafka Connect..."
until curl -s http://localhost:8083/connectors > /dev/null 2>&1; do
    echo "Kafka Connect еще не готов, ждем..."
    sleep 5
done

echo "Kafka Connect готов!"

# Создаем коннектор
echo "Отправка конфигурации коннектора..."
curl -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d @debezium-connector-config.json

echo ""
echo "Проверка статуса коннектора..."
sleep 3
curl -s http://localhost:8083/connectors/postgres-source-connector/status | jq '.'

echo ""
echo "✓ Debezium PostgreSQL Source Connector создан"
