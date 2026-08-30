name := "SCALE"

version := "0.1.0"

scalaVersion := "2.13.12"

libraryDependencies ++= Seq(
  "org.scalatest" %% "scalatest" % "3.2.17" % Test,
  "org.scala-lang.modules" %% "scala-parser-combinators" % "2.3.0",
  "com.lihaoyi" %% "upickle" % "3.1.0"
)
