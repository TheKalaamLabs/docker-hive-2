#!/bin/bash

# To be consistent with marathon

HDFS_URL=${HDFS_URL-hdfs://0.0.0.0:50030}
HIVE_METASTORE_URIS=${HIVE_METASTORE_URIS:-thrift://$(hostname -i):9083}
sed -i 's;hdfs://0.0.0.0:50030;'$HDFS_URL';g' $HADOOP_PREFIX/etc/hadoop/core-site.xml
sed -i 's;HIVE_METASTORE_URIS;'$HIVE_METASTORE_URIS';g' $HIVE_CONF/hive-site.xml

exec "$@"
