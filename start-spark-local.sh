sudo docker rm -f xgboost-spark-occlum

sudo docker run -it \
	--privileged \
	--net=host \
	--name=xgboost-spark-occlum \
	--cpuset-cpus 10-49 \
	--device=/dev/sgx/enclave \
	--device=/dev/sgx/provision \
	-v /var/run/aesmd/aesm.socket:/var/run/aesmd/aesm.socket \
    -v /home/sdp/diankun/process_data_10G:/opt/occlum_spark/data \
	-e LOCAL_IP=192.168.0.111 \
	-e SGX_MEM_SIZE=36GB \
	xgboost-spark-sgx:2.0 \
	bash /opt/run_spark_on_occlum_glibc.sh $1 && tail -f /dev/null

