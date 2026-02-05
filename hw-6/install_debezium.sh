#!/bin/bash
# Скрипт для проверки Debezium коннектора в Kafka Connect
# Образ debezium/connect уже содержит Debezium коннекторы

echo "Проверка Debezium PostgreSQL Connector..."

# Ждем готовности Kafka Connect
echo "Ожидание готовности Kafka Connect..."
until curl -s http://localhost:8083/connector-plugins > /dev/null 2>&1; do
    echo "Kafka Connect еще не готов, ждем..."
    sleep 5
done

echo "Kafka Connect готов!"

# Проверяем установленные плагины
echo "Проверка установленных коннекторов:"
DEBEZIUM_CONNECTORS=$(curl -s http://localhost:8083/connector-plugins | jq -r '.[] | select(.class | contains("debezium") or contains("Debezium")) | .class' 2>/dev/null)

if [ -z "$DEBEZIUM_CONNECTORS" ]; then
    echo "Ошибка: Debezium коннекторы не найдены!"
    echo "Проверьте логи: docker-compose logs kafka-connect"
    exit 1
else
    echo "$DEBEZIUM_CONNECTORS"
    echo ""
    echo "✓ Debezium PostgreSQL Connector доступен"
fi
