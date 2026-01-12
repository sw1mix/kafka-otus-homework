package ru.otus.kafka.streams

import akka.actor.ActorSystem
import akka.kafka.scaladsl.{Consumer, Producer}
import akka.kafka.{ConsumerSettings, ProducerSettings, Subscriptions}
import akka.stream.scaladsl.{Broadcast, Flow, GraphDSL, RunnableGraph, ZipWith}
import akka.stream.{ClosedShape, FlowShape, Materializer}
import org.apache.kafka.clients.consumer.ConsumerConfig
import org.apache.kafka.clients.producer.ProducerRecord
import org.apache.kafka.common.serialization.{StringDeserializer, StringSerializer}

import scala.concurrent.duration.DurationInt

/**
 * Akka Streams приложение с Kafka интеграцией (задача со *):
 * - Producer отправляет числа в Kafka
 * - Consumer читает из Kafka и применяет граф обработки
 */
object KafkaStreamsGraphApp extends App {
  implicit val system: ActorSystem = ActorSystem("KafkaStreamsGraphApp")
  implicit val materializer: Materializer = Materializer(system)

  val kafkaBootstrapServers = "localhost:19092"
  val inputTopic = "numbers-input"
  val outputTopic = "numbers-output"

  println("=" * 60)
  println("Akka Streams + Kafka - Обработка чисел из Kafka")
  println("=" * 60)

  // Настройки Consumer
  val consumerSettings = ConsumerSettings(system, new StringDeserializer, new StringDeserializer)
    .withBootstrapServers(kafkaBootstrapServers)
    .withGroupId("akka-streams-group")
    .withProperty(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest")

  // Настройки Producer
  val producerSettings = ProducerSettings(system, new StringSerializer, new StringSerializer)
    .withBootstrapServers(kafkaBootstrapServers)

  // Граф обработки
  val processingGraph = GraphDSL.create() { implicit builder =>
    import GraphDSL.Implicits._

    // Broadcast - разделение на 3 потока
    val broadcast = builder.add(Broadcast[Int](3))

    // Первый поток: умножить на 10
    val multiplyBy10 = Flow[Int].map(_ * 10)

    // Второй поток: умножить на 2
    val multiplyBy2 = Flow[Int].map(_ * 2)

    // Третий поток: умножить на 3
    val multiplyBy3 = Flow[Int].map(_ * 3)

    // Zip для объединения 3 потоков и сложения
    val zipAndSum = builder.add(
      ZipWith[Int, Int, Int, Int]((a, b, c) => a + b + c)
    )

    // Соединение графа
    broadcast.out(0) ~> multiplyBy10 ~> zipAndSum.in0
    broadcast.out(1) ~> multiplyBy2 ~> zipAndSum.in1
    broadcast.out(2) ~> multiplyBy3 ~> zipAndSum.in2

    FlowShape(broadcast.in, zipAndSum.out)
  }

  // Создаем полный граф: Kafka Consumer -> Обработка -> Kafka Producer
  val kafkaSource = Consumer.plainSource(consumerSettings, Subscriptions.topics(inputTopic))
    .map(record => {
      val value = record.value().toInt
      println(s"Получено из Kafka: $value")
      value
    })

  // Преобразование Int в ProducerRecord для Kafka
  val toProducerRecord = Flow[Int].map { result =>
    val record = new ProducerRecord[String, String](outputTopic, result.toString)
    println(s"Отправка в Kafka: $result")
    record
  }

  // Kafka Producer
  val kafkaSink = Producer.plainSink(producerSettings)

  // Соединяем: Source -> Processing Graph -> Producer Record -> Sink
  val stream = kafkaSource
    .via(processingGraph)
    .via(toProducerRecord)
    .to(kafkaSink)

  println(s"\nОжидание сообщений из топика '$inputTopic'...")
  println(s"Результаты будут отправлены в топик '$outputTopic'")
  println("\nДля отправки чисел используйте:")
  println(s"  docker-compose exec kafka kafka-console-producer \\")
  println(s"    --topic $inputTopic \\")
  println(s"    --bootstrap-server localhost:9092")

  // Запуск потока
  val future = stream.run()

  // Обработчик завершения
  sys.addShutdownHook {
    println("\nЗавершение приложения...")
    system.terminate()
  }

  // Ждем завершения (приложение будет работать до остановки)
  scala.io.StdIn.readLine()
}
