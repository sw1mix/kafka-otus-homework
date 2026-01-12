package ru.otus.kafka.streams

import akka.actor.ActorSystem
import akka.kafka.scaladsl.Producer
import akka.kafka.{ProducerSettings, Subscriptions}
import akka.stream.scaladsl.Source
import akka.stream.Materializer
import org.apache.kafka.clients.producer.ProducerRecord
import org.apache.kafka.common.serialization.StringSerializer

import scala.concurrent.duration.DurationInt

/**
 * Простой Producer для отправки чисел в Kafka
 */
object KafkaProducerApp extends App {
  implicit val system: ActorSystem = ActorSystem("KafkaProducerApp")
  implicit val materializer: Materializer = Materializer(system)

  val kafkaBootstrapServers = "localhost:19092"
  val topic = "numbers-input"

  val producerSettings = ProducerSettings(system, new StringSerializer, new StringSerializer)
    .withBootstrapServers(kafkaBootstrapServers)

  println("=" * 60)
  println("Kafka Producer - Отправка чисел")
  println("=" * 60)

  // Создаем источник чисел от 1 до 5
  val numbers = Source(1 to 5)
    .throttle(1, 1.second) // Отправляем по одному числу в секунду
    .map { num =>
      val record = new ProducerRecord[String, String](topic, num.toString)
      println(s"Отправка: $num")
      record
    }

  val future = numbers
    .runWith(Producer.plainSink(producerSettings))

  future.onComplete { _ =>
    println("\nВсе числа отправлены!")
    system.terminate()
  }(system.dispatcher)

  Thread.sleep(10000)
}
