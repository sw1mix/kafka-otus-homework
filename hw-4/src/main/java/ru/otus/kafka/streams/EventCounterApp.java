package ru.otus.kafka.streams;

import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.common.serialization.Serdes;
import org.apache.kafka.streams.KafkaStreams;
import org.apache.kafka.streams.KeyValue;
import org.apache.kafka.streams.StreamsBuilder;
import org.apache.kafka.streams.StreamsConfig;
import org.apache.kafka.streams.kstream.*;
import org.apache.kafka.streams.processor.WallclockTimestampExtractor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.time.Duration;
import java.util.Properties;

/**
 * Kafka Streams приложение для подсчета количества событий с одинаковыми key
 * в рамках сессии 5 минут.
 */
public class EventCounterApp {
    private static final Logger logger = LoggerFactory.getLogger(EventCounterApp.class);
    
    private static final String INPUT_TOPIC = "events";
    private static final String OUTPUT_TOPIC = "events-count";
    private static final String APPLICATION_ID = "event-counter-app";
    private static final Duration SESSION_TIMEOUT = Duration.ofMinutes(5);
    
    public static void main(String[] args) {
        logger.info("Запуск Kafka Streams приложения для подсчета событий");
        
        Properties props = new Properties();
        props.put(StreamsConfig.APPLICATION_ID_CONFIG, APPLICATION_ID);
        props.put(StreamsConfig.BOOTSTRAP_SERVERS_CONFIG, "localhost:19092");
        props.put(StreamsConfig.DEFAULT_KEY_SERDE_CLASS_CONFIG, Serdes.String().getClass());
        props.put(StreamsConfig.DEFAULT_VALUE_SERDE_CLASS_CONFIG, Serdes.String().getClass());
        props.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest");
        props.put(StreamsConfig.DEFAULT_TIMESTAMP_EXTRACTOR_CLASS_CONFIG, WallclockTimestampExtractor.class.getName());
        
        StreamsBuilder builder = new StreamsBuilder();
        
        // Читаем из входного топика
        KStream<String, String> events = builder.stream(INPUT_TOPIC);
        
        // Группируем по key и применяем session window 5 минут
        KTable<Windowed<String>, Long> eventCounts = events
                .groupByKey(Grouped.with(Serdes.String(), Serdes.String()))
                .windowedBy(SessionWindows.with(SESSION_TIMEOUT))
                .count();
        
        // Преобразуем Windowed<String> в String для вывода
        KStream<String, String> output = eventCounts
                .toStream()
                .map((windowedKey, count) -> {
                    String key = windowedKey.key();
                    long windowStart = windowedKey.window().start();
                    long windowEnd = windowedKey.window().end();
                    String value = String.format("Key: %s, Count: %d, Window: [%d - %d]", 
                            key, count, windowStart, windowEnd);
                    logger.info("Результат: {}", value);
                    return KeyValue.pair(key, value);
                });
        
        // Записываем результаты в выходной топик
        output.to(OUTPUT_TOPIC, Produced.with(Serdes.String(), Serdes.String()));
        
        // Также выводим в консоль для удобства
        output.foreach((key, value) -> {
            System.out.println(">>> " + value);
        });
        
        KafkaStreams streams = new KafkaStreams(builder.build(), props);
        
        // Обработчик завершения
        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            logger.info("Завершение приложения...");
            streams.close();
        }));
        
        try {
            streams.start();
            logger.info("Kafka Streams приложение запущено. Ожидание событий...");
            logger.info("Отправляйте сообщения в топик '{}' используя console producer", INPUT_TOPIC);
        } catch (Exception e) {
            logger.error("Ошибка при запуске приложения", e);
            System.exit(1);
        }
    }
}
