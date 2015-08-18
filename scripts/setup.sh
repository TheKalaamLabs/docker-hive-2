#!/bin/bash

# To be consistent with marathon

HDFS_URL=${HDFS_URL-hdfs://0.0.0.0:50030}
sed -i 's;hdfs://0.0.0.0:50030;'$HDFS_URL';g' $HADOOP_PREFIX/etc/hadoop/core-site.xml

exec "$@"
