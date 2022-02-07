package occlumxgboost

import org.apache.spark.sql.Row

class Task extends Serializable{
  def rowToLibsvm(row: Row): String = {
    0 until row.length flatMap {
      case 0 => Some(row(0).toString)
      case i if row(i) == null => Some("-999")
      case i => Some( (if (i < 14) row(i) else java.lang.Long.parseLong(row(i).toString, 16)).toString )
    } mkString " "
  }
}