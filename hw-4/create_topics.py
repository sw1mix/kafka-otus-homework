#!/usr/bin/env python3
"""
Скрипт для создания топиков events и events-count в Kafka.
"""

import subprocess
import sys
import os


def create_topics():
    """Создает топики через Kafka CLI в docker контейнере."""
    print("Создание топиков через Kafka CLI...")
    
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
    
    topics = [
        {'name': 'events', 'partitions': 1, 'replication': 1},
        {'name': 'events-count', 'partitions': 1, 'replication': 1}
    ]
    
    for topic in topics:
        print(f"Создание {topic['name']}...")
        try:
            result = subprocess.run(
                [
                    'docker-compose', 'exec', '-T', 'kafka',
                    'kafka-topics', '--create',
                    '--bootstrap-server', 'localhost:9092',
                    '--topic', topic['name'],
                    '--partitions', str(topic['partitions']),
                    '--replication-factor', str(topic['replication']),
                    '--if-not-exists'
                ],
                capture_output=True,
                text=True,
                cwd=script_dir
            )
            if result.returncode == 0:
                print(f"✓ {topic['name']} создан или уже существует")
            else:
                if 'already exists' in result.stderr.lower() or 'TopicExistsException' in result.stderr:
                    print(f"⚠ {topic['name']} уже существует")
                else:
                    print(f"⚠ Ошибка при создании {topic['name']}: {result.stderr}")
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
