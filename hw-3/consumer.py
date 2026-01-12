#!/usr/bin/env python3
"""
Consumer приложение для чтения сообщений из Kafka.
Читает только подтвержденные транзакции (isolation.level=read_committed).
"""

from confluent_kafka import Consumer, KafkaException
import json
import sys
import signal


def create_consumer(topics: list):
    """Создает Kafka consumer с настройкой read_committed."""
    config = {
        'bootstrap.servers': 'localhost:19092',
        'group.id': 'transaction-consumer-group',
        'auto.offset.reset': 'earliest',
        'enable.auto.commit': True,
        # Критически важно: читаем только подтвержденные транзакции
        'isolation.level': 'read_committed'
    }
    consumer = Consumer(config)
    consumer.subscribe(topics)
    return consumer


def main():
    """Основная функция."""
    topic1 = 'topic1'
    topic2 = 'topic2'
    topics = [topic1, topic2]
    
    print("="*60)
    print("Kafka Consumer (read_committed)")
    print("="*60)
    print(f"\nЧтение сообщений из топиков: {', '.join(topics)}")
    print("Режим: read_committed (только подтвержденные транзакции)")
    print("\nОжидание сообщений...\n")
    
    consumer = create_consumer(topics)
    
    # Обработчик для корректного завершения
    def signal_handler(sig, frame):
        print("\n\nПолучен сигнал завершения. Закрытие consumer...")
        consumer.close()
        sys.exit(0)
    
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    message_count = {topic1: 0, topic2: 0}
    transactions_seen = set()
    
    try:
        while True:
            msg = consumer.poll(timeout=10.0)
            
            if msg is None:
                print("\nТаймаут ожидания сообщений (10 сек). Завершение...")
                break
            
            if msg.error():
                if msg.error().code() == KafkaException._PARTITION_EOF:
                    # Достигнут конец раздела
                    continue
                else:
                    print(f"Ошибка Kafka: {msg.error()}")
                    break
            
            topic = msg.topic()
            partition = msg.partition()
            offset = msg.offset()
            key = msg.key().decode('utf-8') if msg.key() else None
            value = json.loads(msg.value().decode('utf-8'))
            
            message_count[topic] += 1
            transaction_name = value.get('transaction', 'unknown')
            transactions_seen.add(transaction_name)
            
            print(f"[{topic}] partition={partition}, offset={offset}, key={key}")
            print(f"  Transaction: {transaction_name}")
            print(f"  Message #{value.get('message_number', 'N/A')}")
            print(f"  Timestamp: {value.get('timestamp', 'N/A')}")
            print(f"  Data: {json.dumps(value, indent=2)}")
            print("-" * 60)
            
    except KeyboardInterrupt:
        print("\n\nПрервано пользователем")
    except Exception as e:
        print(f"Ошибка: {e}")
    finally:
        consumer.close()
        print("\n" + "="*60)
        print("Итоговая статистика:")
        print("="*60)
        print(f"  {topic1}: {message_count[topic1]} сообщений")
        print(f"  {topic2}: {message_count[topic2]} сообщений")
        print(f"  Всего: {sum(message_count.values())} сообщений")
        print(f"\n  Увиденные транзакции: {', '.join(sorted(transactions_seen))}")
        print("\n  Ожидаемый результат:")
        print("    - Должны быть видны только сообщения из 'transaction-1-committed'")
        print("    - Сообщения из 'transaction-2-aborted' НЕ должны быть видны")


if __name__ == '__main__':
    main()
