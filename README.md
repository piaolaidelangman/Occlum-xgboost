# Occlum-xgboost

rm -rf /home/sdp/diankun/process_data_10G && \
$SPARK_HOME/bin/spark-submit   \
  --master local[8] \
  --conf spark.task.cpus=8  \
  --class occlumxgboost.PrepareData \
  --conf spark.executor.instances=8 \
  --executor-cores 8 \
  --total-executor-cores 64 \
  --executor-memory 8G \
  --conf spark.kryoserializer.buffer.max=1024m \
  target/xgboostsparksgx-1.0-SNAPSHOT-jar-with-dependencies.jar \
  /home/sdp/diankun/data/10G_data /home/sdp/diankun/process_data_10G 40

$SPARK_HOME/bin/spark-submit   \
  --master local[16] \
  --conf spark.task.cpus=16 \
  --class occlumxgboost.xgbClassifierTrainingExample \
  --conf spark.scheduler.maxRegisteredResourcesWaitingTime=50000000 \
  --conf spark.worker.timeout=60000000 \
  --conf spark.network.timeout=10000000 \
  --conf spark.starvation.timeout=2500000 \
  --conf spark.speculation=false \
  --conf spark.executor.heartbeatInterval=10000000 \
  --conf spark.shuffle.io.maxRetries=8 \
  --num-executors 8 \
  --executor-cores 4 \
  --executor-memory 8G \
  --driver-memory 16G \
  target/xgboostsparksgx-1.0-SNAPSHOT-jar-with-dependencies.jar \
  /home/sdp/diankun/process_data_10G 8

$SPARK_HOME/bin/spark-submit   \
    --master local[16] \
    --conf spark.task.cpus=16 \
    --class occlumxgboost.xgbClassifierTrainingExample \
    --conf spark.scheduler.maxRegisteredResourcesWaitingTime=50000000 \
    --conf spark.worker.timeout=60000000 \
    --conf spark.network.timeout=10000000 \
    --conf spark.starvation.timeout=2500000 \
    --conf spark.speculation=false \
    --conf spark.executor.heartbeatInterval=10000000 \
    --conf spark.sql.shuffle.partitions=400 \
    --conf spark.shuffle.io.maxRetries=8 \
    --conf spark.driver.maxResultSize=8g \
    --conf spark.driver.memoryOverhead=20g \
    --conf spark.executor.memoryOverhead=2g \
    --conf spark.kryoserializer.buffer.max=1024m \
    --conf spark.memory.offHeap.enabled=true \
    --conf spark.memory.offHeap.size=8g \
    --conf spark.storage.memoryMapThreshold=8m \
    --conf spark.task.reaper.threadDump=false \
    --conf spark.sql.files.maxPartitionBytes=512m \
    --conf spark.sql.inMemoryColumnarStorage.enableVectorizedReader=false \
    --num-executors 8 \
    --executor-cores 4 \
    --executor-memory 8G \
    --driver-memory 32G \
    target/xgboostsparksgx-1.0-SNAPSHOT-jar-with-dependencies.jar \
    /home/sdp/diankun/process_data_10G /tmp/model 8