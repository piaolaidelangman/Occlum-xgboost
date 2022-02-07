package occlumxgboost

import org.apache.spark.sql.{SparkSession, Row}

object PrepareData {

  def main(args: Array[String]): Unit = {

    val spark = SparkSession.builder().getOrCreate()
    import spark.implicits._

    val task = new Task()

    val input_path = args(0) // path to iris.data
    val output_path = args(1) // save to this path

    var df = spark.read.option("header", "false").option("inferSchema", "true").option("delimiter", "\t").csv(input_path)
    df.show()

    df.rdd.map(task.rowToLibsvm).saveAsTextFile(output_path)

    spark.stop()
  }
}