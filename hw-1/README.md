1. Написал *docker-compose.yml* с кафкой версии 7.4.0.
2. Запустил контейнеры.
3. Перешел в консоль контейнера:
``` 
docker exec -it hw-1-kafka-1 bash 
```
4. Создал топик *i_dyachenko*:
```
[appuser@kafka ~]$ /usr/bin/kafka-topics --create --topic i_dyachenko --bootstrap-server localhost:9092
WARNING: Due to limitations in metric names, topics with a period ('.') or underscore ('_') could collide. To avoid issues it is best to use either, but not both.
Created topic i_dyachenko.
```
5. Записал сообщения в топик:
```
[appuser@kafka ~]$ /usr/bin/kafka-console-producer --topic i_dyachenko --bootstrap-server localhost:9092
>test1
>test2
>message
```
6. Вычитал сообщения:
```
[appuser@kafka ~]$ /usr/bin/kafka-console-consumer --topic i_dyachenko --from-beginning --group test --bootstrap-server localhost:9092
test1
test2
message
^CProcessed a total of 3 messages
```
Решил проверить без опции --from-beginning и записал сообщение в соседнем терминале **final message test**:
```
[appuser@kafka ~]$ /usr/bin/kafka-console-consumer --topic i_dyachenko --group test --bootstrap-server localhost:9092
final message test
^CProcessed a total of 1 messages
```

