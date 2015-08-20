#!/usr/bin/env sh

PROJECT_HOME="$(cd "$(dirname "$0")"/..; pwd)"

. $PROJECT_HOME/hack/set-default.sh

HIVE_METASTORE_URIS=thrift://$(hostname -i):9083
docker run -d \
	--net=host \
	-e HDFS_URL=$HDFS_URL \
	-e HIVE_METASTORE_URIS=$HIVE_METASTORE_URIS \
	$IMAGE /scripts/hiveserver2-bootstrap.sh
