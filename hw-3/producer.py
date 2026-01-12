#!/usr/bin/env python3
"""
Producer приложение с транзакциями Kafka.
Отправляет сообщения в два топика с использованием транзакций.
"""

from confluent_kafka import Producer
from confluent_kafka.cimpl import KafkaException
import json
import time
import sys


def create_producer(transactional_id: str):
    """Создает Kafka producer с поддержкой транзакций."""
    config = {
        'bootstrap.servers': 'localhost:19092',
        'transactional.id': transactional_id,
        'enable.idempotence': True,
        'acks': 'all',
        'retries': 3,
        'max.in.flight.requests.per.connection': 1
    }
    producer = Producer(config)
    return producer


def delivery_callback(err, msg, msg_num):
    """Коллбэк для подтверждения доставки сообщения."""
    if err is not None:
        print(f"  ✗ Ошибка доставки сообщения {msg_num}: {err}")
    else:
        print(f"  ✓ Сообщение {msg_num} отправлено: partition={msg.partition()}, offset={msg.offset()}")


def send_messages_in_transaction(producer, topic1: str, topic2: str, 
                                  num_messages: int, transaction_name: str):
    """Отправляет сообщения в транзакции."""
    print(f"\n{'='*60}")
    print(f"Начало транзакции: {transaction_name}")
    print(f"{'='*60}")
    
    transaction_started = False
    try:
        # Начинаем транзакцию
        producer.begin_transaction()
        transaction_started = True
        print(f"Транзакция '{transaction_name}' открыта")
        
        # Отправляем сообщения в topic1
        print(f"\nОтправка {num_messages} сообщений в {topic1}:")
        for i in range(1, num_messages + 1):
            message = {
                'transaction': transaction_name,
                'topic': topic1,
                'message_number': i,
                'timestamp': time.time()
            }
            producer.produce(
                topic1,
                key=f"key-{i}",
                value=json.dumps(message).encode('utf-8'),
                callback=lambda err, msg, i=i: delivery_callback(err, msg, i)
            )
            producer.poll(0)  # Обработка коллбэков
        
        # Ждем доставки всех сообщений
        producer.flush()
        
        # Отправляем сообщения в topic2
        print(f"\nОтправка {num_messages} сообщений в {topic2}:")
        for i in range(1, num_messages + 1):
            message = {
                'transaction': transaction_name,
                'topic': topic2,
                'message_number': i,
                'timestamp': time.time()
            }
            producer.produce(
                topic2,
                key=f"key-{i}",
                value=json.dumps(message).encode('utf-8'),
                callback=lambda err, msg, i=i: delivery_callback(err, msg, i)
            )
            producer.poll(0)  # Обработка коллбэков
        
        # Ждем доставки всех сообщений
        producer.flush()
        
        return True, transaction_started
        
    except KafkaException as e:
        print(f"Ошибка при отправке сообщений: {e}")
        return False, transaction_started


def main():
    """Основная функция."""
    topic1 = 'topic1'
    topic2 = 'topic2'
    
    print("="*60)
    print("Kafka Producer с транзакциями")
    print("="*60)
    
    # Создаем producer для первой транзакции
    producer1 = create_producer('transaction-producer-1')
    
    # Инициализируем транзакции (обязательно перед использованием)
    producer1.init_transactions()
    
    # Первая транзакция: отправляем по 5 сообщений и подтверждаем
    print("\n[ТРАНЗАКЦИЯ 1: БУДЕТ ПОДТВЕРЖДЕНА]")
    success, tx_started = send_messages_in_transaction(
        producer1, topic1, topic2, 5, 'transaction-1-committed'
    )
    
    if success and tx_started:
        # Подтверждаем транзакцию
        producer1.commit_transaction()
        print(f"\n✓ Транзакция 'transaction-1-committed' ПОДТВЕРЖДЕНА")
    else:
        if tx_started:
            producer1.abort_transaction()
        print(f"\n✗ Транзакция 'transaction-1-committed' ОТМЕНЕНА из-за ошибки")
        sys.exit(1)
    
    # Закрываем первый producer
    producer1.flush()
    producer1 = None
    time.sleep(1)  # Небольшая пауза между транзакциями
    
    # Создаем producer для второй транзакции
    producer2 = create_producer('transaction-producer-2')
    
    # Инициализируем транзакции (обязательно перед использованием)
    producer2.init_transactions()
    
    # Вторая транзакция: отправляем по 2 сообщения и отменяем
    print("\n[ТРАНЗАКЦИЯ 2: БУДЕТ ОТМЕНЕНА]")
    success, tx_started = send_messages_in_transaction(
        producer2, topic1, topic2, 2, 'transaction-2-aborted'
    )
    
    if tx_started:
        # Отменяем транзакцию
        producer2.abort_transaction()
        if success:
            print(f"\n✗ Транзакция 'transaction-2-aborted' ОТМЕНЕНА (abort)")
        else:
            print(f"\n✗ Транзакция 'transaction-2-aborted' ОТМЕНЕНА из-за ошибки")
    
    # Закрываем второй producer
    producer2.flush()
    producer2 = None
    
    print("\n" + "="*60)
    print("Все транзакции завершены!")
    print("="*60)
    print("\nИтого:")
    print("  - Транзакция 1 (подтверждена): по 5 сообщений в каждый топик")
    print("  - Транзакция 2 (отменена): по 2 сообщения в каждый топик")
    print("\nConsumer должен прочитать только сообщения из транзакции 1.")


if __name__ == '__main__':
    main()
