#!/usr/bin/env sh

PROJECT_HOME="$(cd "$(dirname "$0")"/..; pwd)"

. $PROJECT_HOME/hack/set-default.sh

docker run -d \
	--net=host \
	-e HDFS_URL=$HDFS_URL \
	$IMAGE /scripts/hive-metastore-bootstrap.sh
