package occlumxgboost

// import com.intel.analytics.bigdl.dllib.utils.Engine

import ml.dmlc.xgboost4j.scala.spark.{XGBoostClassificationModel, XGBoostClassifier}
import org.apache.spark.ml.feature.VectorAssembler
import org.apache.spark.sql.functions._
import org.apache.spark.sql.{DataFrame, Dataset}
import org.apache.spark.sql.types._


class XGBClassifier (val xgboostParams: Map[String, Any] = Map()) {
  private val model = new XGBoostClassifier(xgboostParams)
//   model.setNthread(Engine.coreNumber())
//   model.setMaxBins(256)

  def setFeaturesCol(featuresColName: String): this.type = {
    model.setFeaturesCol(featuresColName)
    this
  }

  def fit(df: DataFrame): XGBClassifierModel = {
    // df.repartition(Engine.nodeNumber())
    val xgbmodel = model.fit(df)
    new XGBClassifierModel(xgbmodel)
  }

  def setNthread(value: Int): this.type = {
    model.setNthread(value)
    this
  }

  def setNumRound(value: Int): this.type = {
    model.setNumRound(value)
    this
  }

  def setNumWorkers(value: Int): this.type = {
    model.setNumWorkers(value)
    this
  }

  def setEta(value: Double): this.type = {
    model.setEta(value)
    this
  }

  def setGamma(value: Int): this.type = {
    model.setGamma(value)
    this
  }

  def setMaxDepth(value: Int): this.type = {
    model.setMaxDepth(value)
    this
  }

  def setMissing(value: Float): this.type = {
    model.setMissing(value)
    this
  }

  def setLabelCol(labelColName: String): this.type = {
    model.setLabelCol(labelColName)
    this
  }
  def setTreeMethod(value: String): this.type = {
    model.setTreeMethod(value)
    this
  }

  def setObjective(value: String): this.type = {
    model.setObjective(value)
    this
  }

  def setNumClass(value: Int): this.type = {
    model.setNumClass(value)
    this
  }

  def setTimeoutRequestWorkers(value: Long): this.type = {
    model.setTimeoutRequestWorkers(value)
    this
  }
}
/**
 * [[XGBClassifierModel]] is a trained XGBoost classification model.
 * The prediction column will have the prediction results.
 *
 * @param model trained XGBoostClassificationModel to use in prediction.
 */
class XGBClassifierModel (
  val model: XGBoostClassificationModel) {
  private var featuresCols: Array[String] = null
  private var predictionCol: String = null

  def setFeaturesCol(featuresColName: Array[String]): this.type = {
    require(featuresColName.length > 1, "Please set a valid feature columns")
    featuresCols = featuresColName
    this
  }

  def setPredictionCol(value: String): this.type = {
    predictionCol = value
    this
  }

  def setInferBatchSize(value: Int): this.type = {
    model.setInferBatchSize(value)
    this
  }

  def transform(dataset: DataFrame): DataFrame = {
    require(featuresCols!=None, "Please set feature columns before transform")
    val featureVectorAssembler = new VectorAssembler()
      .setInputCols(featuresCols)
      .setOutputCol("featureAssembledVector")
    val assembledDF = featureVectorAssembler.transform(dataset)
    import org.apache.spark.sql.functions.{col, udf}
    import org.apache.spark.ml.linalg.Vector
    val asDense = udf((v: Vector) => v.toDense)
    val xgbInput = assembledDF.withColumn("DenseFeatures", asDense(col("featureAssembledVector")))
    model.setFeaturesCol("DenseFeatures")
    var output = model.transform(xgbInput).drop("DenseFeatures", "featureAssembledVector")
    if(predictionCol != null) {
      output = output.withColumnRenamed("prediction", predictionCol)
    }
    output
  }

  def save(path: String): Unit = {
    model.write.overwrite().save(path)
  }

}

object XGBClassifierModel {
  // val modelPath = getClass.getResource("/model/0.82/model").getPath
  //   val model = XGBoostClassificationModel.read.load(modelPath)
  // def load(path: String, numClass: Int): XGBClassifierModel = {
  //   // new XGBClassifierModel(XGBoostHelper.load(path, numClass))
  //   new XGBClassifierModel(XGBoostClassificationModel.read.load(modelPath))

  // }

  def load(path: String): XGBClassifierModel = {
    new XGBClassifierModel(XGBoostClassificationModel.load(path))
  }

}
