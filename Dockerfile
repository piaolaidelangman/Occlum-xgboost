FROM 10.239.45.10/arda/intelanalytics/bigdl-ppml-trusted-big-data-ml-scala-occlum:0.14.0-SNAPSHOT

# COPY --from=bigdl /opt/apache-maven-3.6.3 /opt/apache-maven-3.6.3
# maven
# RUN cd /opt && \
#     wget https://archive.apache.org/dist/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz && \
#     tar -zxvf apache-maven-3.6.3-bin.tar.gz

# Prepare xgboost-spark-sgx
# RUN cd /opt && \
#     git clone https://github.com/piaolaidelangman/Occlum-xgboost.git && \
#     cd ./xgboost-spark-sgx && \
#     git fetch origin pull/5/head:test && git checkout test && \
#     /opt/apache-maven-3.6.3/bin/mvn clean package

ADD xgboostsparksgx-1.0-SNAPSHOT-jar-with-dependencies.jar /opt

# Copy scripts & other files
ADD ./run_spark_on_occlum_glibc.sh /opt/run_spark_on_occlum_glibc.sh

RUN chmod a+x /opt/run_spark_on_occlum_glibc.sh
