# sbt Build Patterns

## Basic build.sbt
```scala
name := "data-processing-spark"
version := "1.0.0"
scalaVersion := "2.13.14"

libraryDependencies ++= Seq(
  "org.apache.spark" %% "spark-sql" % "3.5.0" % "provided",
  "org.apache.spark" %% "spark-core" % "3.5.0" % "provided",
  "org.scalatest" %% "scalatest" % "3.2.18" % Test,
  "io.delta" %% "delta-spark" % "3.1.0"
)
```

## Plugins
```scala
// project/plugins.sbt
addSbtPlugin("org.scalameta" % "sbt-scalafmt" % "2.5.2")
addSbtPlugin("ch.epfl.scala" % "sbt-scalafix" % "0.12.1")
```

## Common Commands
```bash
sbt compile          # compile project
sbt test             # run tests
sbt scalafmtCheck    # check formatting
sbt scalafix --check # check linting
sbt assembly         # build fat jar
```
