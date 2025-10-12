# Kafka в KRaft + SASL/PLAIN + ACL (Docker)

## Назначение файлов

- `docker-compose.yml`
  - Запускает контейнер `apache/kafka:3.8.0`.
  - При первом старте автоматически форматирует KRaft (`kafka-storage.sh format`) и запускает брокер.
  - Healthcheck использует SASL-конфиг (`client-admin.properties`), чтобы не ломать рукопожатие.

- `config/server.properties`
  - Базовая конфигурация одноузлового KRaft-брокера и контроллера.
  - Критичные параметры:
    - `controller.listener.names=CONTROLLER` — **без комментариев** на строке.
    - `listeners=PLAINTEXT://:9092,SASL_PLAINTEXT://:9093,CONTROLLER://:9094`
    - `advertised.listeners=PLAINTEXT://kafka:9092,SASL_PLAINTEXT://kafka:9093`
    - `listener.security.protocol.map=PLAINTEXT:PLAINTEXT,SASL_PLAINTEXT:SASL_PLAINTEXT,CONTROLLER:PLAINTEXT`
    - `inter.broker.listener.name=SASL_PLAINTEXT`
    - `authorizer.class.name=org.apache.kafka.metadata.authorizer.StandardAuthorizer`
    - `super.users=User:admin;User:ANONYMOUS` — `ANONYMOUS` нужен для контроллера на PLAINTEXT.
    - `allow.everyone.if.no.acl.found=false` — по умолчанию всё запрещено.

- `config/jaas-kafka.conf`
  - JAAS для сервера (SASL/PLAIN). Описывает пользователей `admin`, `alice`, `bob`, `charlie` и их пароли.

- `config/client-admin.properties`
  - Клиентские настройки SASL/PLAIN для `admin` (используются в админ-CLI через `--command-config`).

- `config/client-alice.properties`
  - Клиентские настройки SASL/PLAIN для `alice` (продюсер — запись).

- `config/client-bob.properties`
  - Клиентские настройки SASL/PLAIN для `bob` (консюмер — чтение).

- `config/client-charlie.properties`
  - Клиентские настройки SASL/PLAIN для `charlie` (прав нет).

- `data/`
  - Данные KRaft: `meta.properties` и журналы. Удаление переформатирует кластер.

---

## Команды (пошаговый сценарий)


### Создание топика
```
root@car:~/OTUS-kafka/kafka-otus-homework/hw-2# docker exec -it kafka bash -lc '
/opt/kafka/bin/kafka-topics.sh --create \
  --topic secure-topic --partitions 1 --replication-factor 1 \
  --bootstrap-server kafka:9093 \
  --command-config /opt/kafka/config/client-admin.properties
'
Created topic secure-topic.
```

### ACL: выдаём права
```
root@car:~/OTUS-kafka/kafka-otus-homework/hw-2# docker exec -it kafka bash -lc '
/opt/kafka/bin/kafka-acls.sh --bootstrap-server kafka:9093 \
  --command-config /opt/kafka/config/client-admin.properties \
  --add --allow-principal User:alice \
  --operation Write --operation Describe \
  --topic secure-topic
'
Adding ACLs for resource `ResourcePattern(resourceType=TOPIC, name=secure-topic, patternType=LITERAL)`: 
        (principal=User:alice, host=*, operation=DESCRIBE, permissionType=ALLOW)
        (principal=User:alice, host=*, operation=WRITE, permissionType=ALLOW) 

Current ACLs for resource `ResourcePattern(resourceType=TOPIC, name=secure-topic, patternType=LITERAL)`: 
        (principal=User:alice, host=*, operation=WRITE, permissionType=ALLOW)
        (principal=User:alice, host=*, operation=DESCRIBE, permissionType=ALLOW) 

root@car:~/OTUS-kafka/kafka-otus-homework/hw-2# docker exec -it kafka bash -lc '
/opt/kafka/bin/kafka-acls.sh --bootstrap-server kafka:9093 \
  --command-config /opt/kafka/config/client-admin.properties \
  --add --allow-principal User:bob \
  --operation Read --operation Describe \
  --topic secure-topic
'
Adding ACLs for resource `ResourcePattern(resourceType=TOPIC, name=secure-topic, patternType=LITERAL)`: 
        (principal=User:bob, host=*, operation=DESCRIBE, permissionType=ALLOW)
        (principal=User:bob, host=*, operation=READ, permissionType=ALLOW) 

Current ACLs for resource `ResourcePattern(resourceType=TOPIC, name=secure-topic, patternType=LITERAL)`: 
        (principal=User:alice, host=*, operation=WRITE, permissionType=ALLOW)
        (principal=User:bob, host=*, operation=READ, permissionType=ALLOW)
        (principal=User:bob, host=*, operation=DESCRIBE, permissionType=ALLOW)
        (principal=User:alice, host=*, operation=DESCRIBE, permissionType=ALLOW) 
```

### Список топиков от имени каждого пользователя
```
root@car:~/OTUS-kafka/kafka-otus-homework/hw-2# docker exec -it kafka bash -lc '
/opt/kafka/bin/kafka-topics.sh --list \
  --bootstrap-server kafka:9093 \
  --command-config /opt/kafka/config/client-alice.properties
'
secure-topic
root@car:~/OTUS-kafka/kafka-otus-homework/hw-2# docker exec -it kafka bash -lc '
/opt/kafka/bin/kafka-topics.sh --list \
  --bootstrap-server kafka:9093 \
  --command-config /opt/kafka/config/client-bob.properties
'
secure-topic
root@car:~/OTUS-kafka/kafka-otus-homework/hw-2# docker exec -it kafka bash -lc '
/opt/kafka/bin/kafka-topics.sh --list \
  --bootstrap-server kafka:9093 \
  --command-config /opt/kafka/config/client-charlie.properties || true
'
```
### Запись сообщений в топик
```
# alice (должно пройти)
root@car:~/OTUS-kafka/kafka-otus-homework/hw-2# 
docker exec -it kafka bash -lc '
printf "msg-1-from-alice\nmsg-2-from-alice\n" | \
/opt/kafka/bin/kafka-console-producer.sh \
  --bootstrap-server kafka:9093 \
  --producer.config /opt/kafka/config/client-alice.properties \
  --topic secure-topic
'

# bob — запись запрещена
root@car:~/OTUS-kafka/kafka-otus-homework/hw-2# docker exec -it kafka bash -lc '
printf "msg-1-from-bob\n" | \
/opt/kafka/bin/kafka-console-producer.sh \
  --bootstrap-server kafka:9093 \
  --producer.config /opt/kafka/config/client-bob.properties \
  --topic secure-topic || true
'
[2025-10-12 15:13:47,840] ERROR [Producer clientId=console-producer] Aborting producer batches due to fatal error (org.apache.kafka.clients.producer.internals.Sender)
org.apache.kafka.common.errors.ClusterAuthorizationException: Cluster authorization failed.
[2025-10-12 15:13:47,841] ERROR Error when sending message to topic secure-topic with key: null, value: 14 bytes with error: (org.apache.kafka.clients.producer.internals.ErrorLoggingCallback)
org.apache.kafka.common.errors.ClusterAuthorizationException: Cluster authorization failed.

# charlie — запись запрещена
root@car:~/OTUS-kafka/kafka-otus-homework/hw-2# docker exec -it kafka bash -lc '
printf "msg-1-from-charlie\n" | \
/opt/kafka/bin/kafka-console-producer.sh \
  --bootstrap-server kafka:9093 \
  --producer.config /opt/kafka/config/client-charlie.properties \
  --topic secure-topic || true
'
[2025-10-12 15:13:57,075] WARN [Producer clientId=console-producer] Error while fetching metadata with correlation id 1 : {secure-topic=TOPIC_AUTHORIZATION_FAILED} (org.apache.kafka.clients.NetworkClient)
[2025-10-12 15:13:57,075] ERROR [Producer clientId=console-producer] Topic authorization failed for topics [secure-topic] (org.apache.kafka.clients.Metadata)
[2025-10-12 15:13:57,076] ERROR Error when sending message to topic secure-topic with key: null, value: 18 bytes with error: (org.apache.kafka.clients.producer.internals.ErrorLoggingCallback)
org.apache.kafka.common.errors.TopicAuthorizationException: Not authorized to access topics: [secure-topic]
[2025-10-12 15:13:57,082] ERROR [Producer clientId=console-producer] Error in kafka producer I/O thread while aborting transaction when during closing:  (org.apache.kafka.clients.producer.internals.Sender)
java.lang.IllegalStateException: Transactional method invoked on a non-transactional producer.
        at org.apache.kafka.clients.producer.internals.TransactionManager.ensureTransactional(TransactionManager.java:1019)
        at org.apache.kafka.clients.producer.internals.TransactionManager.handleCachedTransactionRequestResult(TransactionManager.java:1131)
        at org.apache.kafka.clients.producer.internals.TransactionManager.beginAbort(TransactionManager.java:323)
        at org.apache.kafka.clients.producer.internals.Sender.run(Sender.java:276)
        at java.base/java.lang.Thread.run(Unknown Source)
```


### выдаём bob право на consumer group и читаем 2 сообщения

```
root@car:~/OTUS-kafka/kafka-otus-homework/hw-2# docker exec -it kafka bash -lc '
/opt/kafka/bin/kafka-acls.sh --bootstrap-server kafka:9093 \
  --command-config /opt/kafka/config/client-admin.properties \
  --add --allow-principal User:bob --group bob-group --operation Read
'
Adding ACLs for resource `ResourcePattern(resourceType=GROUP, name=bob-group, patternType=LITERAL)`: 
        (principal=User:bob, host=*, operation=READ, permissionType=ALLOW) 

Current ACLs for resource `ResourcePattern(resourceType=GROUP, name=bob-group, patternType=LITERAL)`: 
        (principal=User:bob, host=*, operation=READ, permissionType=ALLOW) 

root@car:~/OTUS-kafka/kafka-otus-homework/hw-2# docker exec -it kafka bash -lc '
/opt/kafka/bin/kafka-console-consumer.sh \
  --bootstrap-server kafka:9093 \
  --consumer.config /opt/kafka/config/client-bob.properties \
  --group bob-group --topic secure-topic \
  --from-beginning --max-messages 2
'
msg-1-from-alice
msg-2-from-alice
Processed a total of 2 messages
root@car:~/OTUS-kafka/kafka-otus-homework/hw-2# 

```



