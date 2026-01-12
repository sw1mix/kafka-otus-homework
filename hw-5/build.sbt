ThisBuild / version := "1.0-SNAPSHOT"
ThisBuild / scalaVersion := "2.13.12"

val AkkaVersion = "2.8.5"
val AlpakkaKafkaVersion = "4.0.0"

lazy val root = (project in file("."))
  .settings(
    name := "akka-streams-homework",
    libraryDependencies ++= Seq(
      "com.typesafe.akka" %% "akka-stream" % AkkaVersion,
      "com.typesafe.akka" %% "akka-stream-kafka" % AlpakkaKafkaVersion,
      "com.typesafe.akka" %% "akka-slf4j" % AkkaVersion,
      "ch.qos.logback" % "logback-classic" % "1.4.11"
    )
  )
