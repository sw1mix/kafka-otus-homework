#!/bin/bash
# Скрипт для добавления данных в тестовую таблицу

echo "Добавление данных в таблицу test_table..."

docker-compose exec -T postgres psql -U postgres -d testdb <<EOF
INSERT INTO test_table (name, email) VALUES
    ('David', 'david@example.com'),
    ('Eve', 'eve@example.com'),
    ('Frank', 'frank@example.com');
EOF

echo "✓ Данные добавлены"
echo ""
echo "Проверка данных в таблице:"
docker-compose exec -T postgres psql -U postgres -d testdb -c "SELECT * FROM test_table ORDER BY id;"
