#!/usr/bin/env python3
"""
Скрипт для создания топиков topic1 и topic2 в Kafka через Kafka CLI.
"""

import subprocess
import sys
import os


def create_topics():
    """Создает топики через Kafka CLI в docker контейнере."""
    print("Создание топиков через Kafka CLI...")
    
    # Получаем путь к текущей директории
    script_dir = os.path.dirname(os.path.abspath(__file__))
    
    # Проверяем, запущен ли docker-compose
    try:
        result = subprocess.run(
            ['docker-compose', 'ps'],
            capture_output=True,
            text=True,
            cwd=script_dir
        )
        if 'kafka' not in result.stdout or 'Up' not in result.stdout:
            print("✗ Kafka контейнер не запущен. Запустите: docker-compose up -d")
            return False
    except FileNotFoundError:
        print("✗ docker-compose не найден")
        return False
    
    topics = ['topic1', 'topic2']
    
    for topic in topics:
        print(f"Создание {topic}...")
        try:
            result = subprocess.run(
                [
                    'docker-compose', 'exec', '-T', 'kafka',
                    'kafka-topics', '--create',
                    '--bootstrap-server', 'localhost:9092',
                    '--topic', topic,
                    '--partitions', '1',
                    '--replication-factor', '1',
                    '--if-not-exists'
                ],
                capture_output=True,
                text=True,
                cwd=script_dir
            )
            if result.returncode == 0:
                print(f"✓ {topic} создан или уже существует")
            else:
                if 'already exists' in result.stderr.lower() or 'TopicExistsException' in result.stderr:
                    print(f"⚠ {topic} уже существует")
                else:
                    print(f"⚠ Ошибка при создании {topic}: {result.stderr}")
        except Exception as e:
            print(f"✗ Ошибка: {e}")
            return False
    
    print("\nПроверка созданных топиков:")
    try:
        result = subprocess.run(
            ['docker-compose', 'exec', '-T', 'kafka', 'kafka-topics', '--list', '--bootstrap-server', 'localhost:9092'],
            capture_output=True,
            text=True,
            cwd=script_dir
        )
        print(result.stdout)
    except Exception as e:
        print(f"⚠ Не удалось проверить список топиков: {e}")
    
    return True


if __name__ == '__main__':
    success = create_topics()
    sys.exit(0 if success else 1)
