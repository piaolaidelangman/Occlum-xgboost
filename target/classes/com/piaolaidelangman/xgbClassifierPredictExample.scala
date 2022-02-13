package occlumxgboost

import org.apache.spark.sql.{SparkSession}
import org.apache.spark.sql.{SparkSession}
import org.apache.spark.SparkContext
import org.apache.spark.sql.types.{DoubleType, StringType, StructField, StructType}

object xgbClassifierPredictExample {
  def main(args: Array[String]): Unit = {
    if (args.length < 2) {
      println("Usage: program input_path model_path")
      sys.exit(1)
    }
    val input_path = args(0)
    val model_path = args(1)

    val sc = new SparkContext()
    val spark = SparkSession.builder().getOrCreate()
    // import spark.implicits._

    val schema = new StructType(Array(
      StructField("sepal length", DoubleType, true),
      StructField("sepal width", DoubleType, true),
      StructField("petal length", DoubleType, true),
      StructField("petal width", DoubleType, true),
      StructField("class", StringType, true)))
    val df = spark.read.schema(schema).csv(input_path)

    val model = XGBClassifierModel.load(model_path)
    model.setFeaturesCol(Array("sepal length", "sepal width", "petal length", "petal width"))

    val results = model.transform(df)
    results.show()

    sc.stop()
  }
}
