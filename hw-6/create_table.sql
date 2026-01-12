-- Создание тестовой таблицы для Debezium CDC
CREATE TABLE IF NOT EXISTS test_table (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Включение логической репликации для Debezium
ALTER TABLE test_table REPLICA IDENTITY FULL;

-- Вставка тестовых данных
INSERT INTO test_table (name, email) VALUES
    ('Alice', 'alice@example.com'),
    ('Bob', 'bob@example.com'),
    ('Charlie', 'charlie@example.com');
