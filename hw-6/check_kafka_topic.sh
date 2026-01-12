#!/bin/bash
# Скрипт для проверки сообщений в Kafka топике

TOPIC="postgres-server.public.test_table"

echo "Проверка сообщений в топике: $TOPIC"
echo ""

docker-compose exec -T kafka kafka-console-consumer \
    --bootstrap-server localhost:9092 \
    --topic "$TOPIC" \
    --from-beginning \
    --max-messages 10 \
    --timeout-ms 10000

echo ""
echo "Для просмотра всех сообщений используйте:"
echo "  docker-compose exec kafka kafka-console-consumer \\"
echo "    --bootstrap-server localhost:9092 \\"
echo "    --topic $TOPIC \\"
echo "    --from-beginning"
