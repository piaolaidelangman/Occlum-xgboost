#!/bin/bash
set -x

BLUE='\033[1;34m'
NC='\033[0m'
occlum_glibc=/opt/occlum/glibc/lib
# occlum-node IP
HOST_IP=`cat /etc/hosts | grep $HOSTNAME | awk '{print $1}'`

init_instance() {
    # Init Occlum instance
    cd /opt
    # check if occlum_spark exists
            # .resource_limits.user_space_size = "102400MB" |
                    # .process.default_stack_size = "4096MB" |
    [[ -d occlum_spark ]] || mkdir occlum_spark
    cd occlum_spark
    occlum init
    new_json="$(jq '.resource_limits.user_space_size = "SGX_MEM_SIZE" |
        .resource_limits.max_num_of_threads = 4096 |
        .resource_limits.kernel_space_heap_size="2048MB" |
        .process.default_heap_size = "32GB" |
        .process.default_mmap_size = "32GB" |
        .entry_points = [ "/usr/lib/jvm/java-11-openjdk-amd64/bin" ] |
        .env.untrusted = [ "DMLC_TRACKER_URI", "SPARK_DRIVER_URL" ] |
        .env.default = [ "LD_LIBRARY_PATH=/usr/lib/jvm/java-11-openjdk-amd64/lib/server:/usr/lib/jvm/java-11-openjdk-amd64/lib:/usr/lib/jvm/java-11-openjdk-amd64/../lib:/lib","SPARK_CONF_DIR=/bin/conf","SPARK_ENV_LOADED=1","PYTHONHASHSEED=0","SPARK_HOME=/bin","SPARK_SCALA_VERSION=2.12","SPARK_JARS_DIR=/bin/jars","LAUNCH_CLASSPATH=/bin/jars/*",""]' Occlum.json)" && \
    echo "${new_json}" > Occlum.json
    echo "SGX_MEM_SIZE ${SGX_MEM_SIZE}"
    if [[ -z "$SGX_MEM_SIZE" ]]; then
        sed -i "s/SGX_MEM_SIZE/20GB/g" Occlum.json
    else
        sed -i "s/SGX_MEM_SIZE/${SGX_MEM_SIZE}/g" Occlum.json
    fi
}

build_spark() {
    # Copy JVM and class file into Occlum instance and build
    cd /opt/occlum_spark
    mkdir -p image/usr/lib/jvm
    cp -r /usr/lib/jvm/java-11-openjdk-amd64 image/usr/lib/jvm
    cp -rf /etc/java-11-openjdk image/etc/
    # Copy K8s secret
    mkdir -p image/var/run/secrets/
    cp -r /var/run/secrets/* image/var/run/secrets/
    ls image/var/run/secrets/kubernetes.io/serviceaccount/
    # Copy libs
    cp /lib/x86_64-linux-gnu/libz.so.1 image/lib
    cp /lib/x86_64-linux-gnu/libz.so.1 image/$occlum_glibc
    cp /lib/x86_64-linux-gnu/libtinfo.so.5 image/$occlum_glibc
    cp /lib/x86_64-linux-gnu/libnss*.so.2 image/$occlum_glibc
    cp /lib/x86_64-linux-gnu/libresolv.so.2 image/$occlum_glibc
    cp $occlum_glibc/libdl.so.2 image/$occlum_glibc
    cp $occlum_glibc/librt.so.1 image/$occlum_glibc
    cp $occlum_glibc/libm.so.6 image/$occlum_glibc
    # Copy libhadoop
    cp /opt/libhadoop.so image/lib
    # Prepare Spark
    mkdir -p image/opt/spark
    cp -rf $SPARK_HOME/* image/opt/spark/
    # Copy etc files
    cp -rf /etc/hosts image/etc/
    echo "$HOST_IP occlum-node" >> image/etc/hosts
    # cat image/etc/hosts

    cp -rf /etc/hostname image/etc/
    cp -rf /etc/ssl image/etc/
    cp -rf /etc/passwd image/etc/
    cp -rf /etc/group image/etc/
    cp -rf /etc/nsswitch.conf image/etc/

    # Prepare xgboost-spark-sgx
    mkdir -p image/bin/jars
    # cp -f /opt/xgboost-spark-sgx/target/xgboostsparksgx-1.0-SNAPSHOT-jar-with-dependencies.jar image/bin/jars
    cp -f /opt/xgboostsparksgx-1.0-SNAPSHOT-jar-with-dependencies.jar image/bin/jars
    occlum build
}

run_spark_pi() {
    init_instance spark
    build_spark
    echo -e "${BLUE}occlum run spark Pi${NC}"
    occlum run /usr/lib/jvm/java-11-openjdk-amd64/bin/java \
                -XX:-UseCompressedOops -XX:MaxMetaspaceSize=256m \
                -XX:ActiveProcessorCount=4 \
                -Divy.home="/tmp/.ivy" \
                -Dos.name="Linux" \
                -cp "$SPARK_HOME/conf/:$SPARK_HOME/jars/*" \
                -Xmx10g org.apache.spark.deploy.SparkSubmit \
                --jars $SPARK_HOME/examples/jars/spark-examples_2.12-3.1.2.jar,$SPARK_HOME/examples/jars/scopt_2.12-3.7.1.jar \
                --class org.apache.spark.examples.SparkPi spark-internal
}
                # -XX:+UseParallelGC \
run_spark_xgboost_train() {
    init_instance spark
    build_spark
    echo -e "occlum run xgboost spark "
    occlum run /usr/lib/jvm/java-11-openjdk-amd64/bin/java \
                -XX:-UseCompressedOops -XX:MaxMetaspaceSize=1024m \
                -XX:ActiveProcessorCount=8 \
                -Divy.home="/tmp/.ivy" \
                -Dos.name="Linux" \
                -cp "$SPARK_HOME/conf/:$SPARK_HOME/jars/*:/bin/jars/*" \
                -Xmx30g -Xms30g org.apache.spark.deploy.SparkSubmit \
                --master local[16] \
                --conf spark.task.cpus=8 \
                --class occlumxgboost.xgbClassifierTrainingExample \
                --num-executors 8 \
                --executor-cores 2 \
                --executor-memory 2G \
                --driver-memory 10G \
                /bin/jars/xgboostsparksgx-1.0-SNAPSHOT-jar-with-dependencies.jar \
                /host/data /host/data/model 8 10 2
}

id=$([ -f "$pid" ] && echo $(wc -l < "$pid") || echo "0")

arg=$1
case "$arg" in
    init)
        init_instance
        build_spark
        ;;
    pi)
        run_spark_pi
        cd ../
        ;;
    xgboost_train)
        run_spark_xgboost_train
        cd ../
        ;;
esac
# Extract mem
                # --conf spark.driver.maxResultSize=16g \
                # --conf spark.driver.memoryOverhead=16g \
                # --conf spark.executor.memoryOverhead=2g \
                # --conf spark.kryoserializer.buffer.max=1024m \
                # --conf spark.memory.offHeap.enabled=true \
                # --conf spark.memory.offHeap.size=8g \


# Dynamic
                # --conf spark.storage.memoryMapThreshold=8m \
                # --conf spark.task.reaper.threadDump=false \
                # --conf spark.sql.files.maxPartitionBytes=512m \
                # --conf spark.sql.inMemoryColumnarStorage.enableVectorizedReader=false \
                # --conf spark.dynamicAllocation.shuffleTracking.enabled=true \
                # --conf spark.shuffle.service.enabled=true \
                # --conf spark.dynamicAllocation.enabled=true \
                # --conf spark.dynamicAllocation.executorIdleTimeout=180s \
                # --conf spark.dynamicAllocation.minExecutors=1 \
                # --conf spark.dynamicAllocation.maxExecutors=8 \
                # --conf spark.dynamicAllocation.schedulerBacklogTimeout=2s \