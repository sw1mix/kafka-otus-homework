package ru.otus.kafka.streams

import akka.actor.ActorSystem
import akka.stream.scaladsl.{Broadcast, Flow, GraphDSL, RunnableGraph, Sink, Source, ZipWith}
import akka.stream.{ClosedShape, Materializer}

import scala.concurrent.Await
import scala.concurrent.duration.DurationInt
import scala.util.{Failure, Success}

/**
 * Akka Streams приложение с графом DSL:
 * - Входной поток целых чисел
 * - Broadcast на 3 потока
 * - Первый поток: умножить на 10
 * - Второй поток: умножить на 2
 * - Третий поток: умножить на 3
 * - Zip для объединения 3 потоков
 * - Сложение элементов из 3 потоков
 */
object StreamsGraphApp extends App {
  implicit val system: ActorSystem = ActorSystem("StreamsGraphApp")
  implicit val materializer: Materializer = Materializer(system)

  println("=" * 60)
  println("Akka Streams Graph DSL - Обработка чисел")
  println("=" * 60)

  // Создаем граф
  val graph = GraphDSL.create() { implicit builder =>
    import GraphDSL.Implicits._

    // Входной поток целых чисел
    val input = Source(1 to 5)

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

    // Sink для вывода результатов
    val output = Sink.foreach[Int] { result =>
      println(s">>> Результат: $result")
    }

    // Соединение графа
    input ~> broadcast.in

    broadcast.out(0) ~> multiplyBy10 ~> zipAndSum.in0
    broadcast.out(1) ~> multiplyBy2 ~> zipAndSum.in1
    broadcast.out(2) ~> multiplyBy3 ~> zipAndSum.in2

    zipAndSum.out ~> output

    ClosedShape
  }

  // Запуск графа
  println("\nЗапуск обработки чисел 1, 2, 3, 4, 5...")
  println("\nОжидаемый результат:")
  println("  1 -> (10, 2, 3) -> 15")
  println("  2 -> (20, 4, 6) -> 30")
  println("  3 -> (30, 6, 9) -> 45")
  println("  4 -> (40, 8, 12) -> 60")
  println("  5 -> (50, 10, 15) -> 75")
  println()

  try {
    RunnableGraph.fromGraph(graph).run()
    // Ждем немного для обработки
    Thread.sleep(2000)
    println("\n" + "=" * 60)
    println("Обработка завершена успешно!")
    println("=" * 60)
  } catch {
    case exception: Exception =>
      println(s"\nОшибка: ${exception.getMessage}")
      exception.printStackTrace()
  } finally {
    system.terminate()
  }
}
